#Requires -Version 7.2
# Disposable SQL Server 2022 CI environment only. Password comes from environment, never CLI args.
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../powershell/Toolkit.psm1') -Force
if (-not $env:TOOLKIT_SQL_PASSWORD) { throw 'TOOLKIT_SQL_PASSWORD is required' }
$credential = [pscredential]::new('sa', (ConvertTo-SecureString $env:TOOLKIT_SQL_PASSWORD -AsPlainText -Force))
function Assert-True($Condition, $Message) { if (-not $Condition) { throw $Message } }
# A heterogeneous two-set batch with NULL and an empty table exercises serialization primitives.
$data = Invoke-ToolkitQuery -Instance 'localhost,1433' -Credential $credential -Sql "SELECT 1 AS n, CAST(NULL AS nvarchar(10)) AS missing; SELECT CAST('x' AS nvarchar(10)) AS label WHERE 1=0;"
Assert-True ($data.Tables.Count -eq 2) 'Result sets lost'
Assert-True ($data.Tables[0].Rows[0]['missing'] -is [DBNull]) 'NULL not retained'
Assert-True ($data.Tables[1].Columns[0].ColumnName -eq 'label') 'Empty schema lost'
$data.Dispose()
& (Join-Path $PSScriptRoot '../powershell/Invoke-SqlFleetAssessment.ps1') -Instances 'localhost,1433' -Credential $credential -OutputDirectory './artifacts/integration'
$run = Get-ChildItem './artifacts/integration' -Directory | Select-Object -Last 1
$summary = @(Get-Content (Join-Path $run.FullName 'summary.json') -Raw | ConvertFrom-Json)
Assert-True ($summary.Count -eq 5) 'Missing checks'
Assert-True (@($summary | Where-Object status -ne 'collected').Count -eq 0) 'Collector failed'
$ag = $summary | Where-Object check -eq '02_ag_health.sql'
$report = Get-Content (Join-Path $run.FullName $ag.report) -Raw | ConvertFrom-Json
Assert-True ($report.result_sets[0].rows[0].collection_status -eq 'NOT_APPLICABLE') 'HADR-disabled branch incorrect'
# Round-trip actual heterogeneous output through the runner's JSON serialization.
$instance = $summary | Where-Object check -eq '01_instance_health.sql'
$report = Get-Content (Join-Path $run.FullName $instance.report) -Raw | ConvertFrom-Json
Assert-True ($report.result_sets.Count -eq 4) 'Instance result sets lost'
Assert-True ($report.result_sets[0].rows[0].product_version) 'Missing instance metadata'
Write-Output 'SQL Server integration assertions passed. Multi-replica AG and restore drills are separate manual gates.'
if ($env:TOOLKIT_DISPOSABLE_SQL -ne '1') { throw 'Write tests require TOOLKIT_DISPOSABLE_SQL=1 on the disposable CI lab.' }
function Invoke-LabSql([string]$Sql) {
    $result = Invoke-ToolkitQuery -Instance 'localhost,1433' -Credential $credential -Sql $Sql -QueryTimeout 120
    $result.Dispose()
}
$preflight = Invoke-ToolkitQuery -Instance 'localhost,1433' -Credential $credential -Sql "SELECT COUNT(*) AS existing_count FROM sys.databases WHERE name IN (N'ToolkitBackupTest', N'ToolkitBenchmark');"
$existing = [int]$preflight.Tables[0].Rows[0]['existing_count']
$preflight.Dispose()
if ($existing -ne 0) { throw 'Reserved lab databases already exist; refusing destructive tests.' }
try {
    Invoke-LabSql @"
IF DB_ID(N'ToolkitBackupTest') IS NOT NULL THROW 51000, 'Existing backup lab database', 1;
CREATE DATABASE ToolkitBackupTest;
BACKUP DATABASE ToolkitBackupTest TO DISK=N'/var/opt/mssql/data/toolkit-1.bak', DISK=N'/var/opt/mssql/data/toolkit-2.bak' WITH FORMAT, CHECKSUM;
BACKUP DATABASE ToolkitBackupTest TO DISK=N'/var/opt/mssql/data/toolkit-no-checksum.bak' WITH FORMAT, NO_CHECKSUM;
"@
    $verified = & (Join-Path $PSScriptRoot '../powershell/Test-SqlBackup.ps1') -Instance 'localhost,1433' -Credential $credential -BackupPaths '/var/opt/mssql/data/toolkit-1.bak','/var/opt/mssql/data/toolkit-2.bak' -Confirm:$false
    Assert-True ($verified.stripes -eq 2) 'Striped checksum backup did not verify'
    $rejected = $false
    try {
        & (Join-Path $PSScriptRoot '../powershell/Test-SqlBackup.ps1') -Instance 'localhost,1433' -Credential $credential -BackupPaths '/var/opt/mssql/data/toolkit-no-checksum.bak' -Confirm:$false | Out-Null
    } catch { $rejected = $true }
    Assert-True $rejected 'Checksum-free media should fail CHECKSUM verification'
    $rejected = $false
    try {
        & (Join-Path $PSScriptRoot '../powershell/Test-SqlBackup.ps1') -Instance 'localhost,1433' -Credential $credential -BackupPaths '/var/opt/mssql/data/toolkit-1.bak' -Confirm:$false | Out-Null
    } catch { $rejected = $true }
    Assert-True $rejected 'Incomplete stripe set should fail'
    $setup = Get-Content (Join-Path $PSScriptRoot '../benchmarks/setup.sql') -Raw
    foreach ($batch in [regex]::Split($setup, '(?im)^GO\s*\r?$')) {
        if (-not [string]::IsNullOrWhiteSpace($batch)) { Invoke-LabSql $batch }
    }
    $benchmarkPath = & (Join-Path $PSScriptRoot '../benchmarks/Run-Benchmark.ps1') -Credential $credential -Confirm:$false -Trials 10
    $raw = Get-Content (Join-Path $benchmarkPath 'raw.json') -Raw | ConvertFrom-Json
    Assert-True ($raw.trials.Count -eq 20) 'Missing benchmark trials'
    foreach ($trial in $raw.trials) {
        Assert-True (($trial.sql_messages -join "`n") -match "Table 'Workload'") 'STATISTICS IO messages were not drained'
    }
} finally {
    # Release idle benchmark sessions before dropping only our disposable lab databases.
    [System.Data.SqlClient.SqlConnection]::ClearAllPools()
    Invoke-LabSql "IF DB_ID(N'ToolkitBackupTest') IS NOT NULL DROP DATABASE ToolkitBackupTest;"
    Invoke-LabSql "IF DB_ID(N'ToolkitBenchmark') IS NOT NULL DROP DATABASE ToolkitBenchmark;"
}
Write-Output 'Backup positive/negative cases and synthetic benchmark completed.'
