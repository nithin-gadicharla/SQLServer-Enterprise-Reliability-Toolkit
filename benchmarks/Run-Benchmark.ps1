#Requires -Version 7.2
<#
.SYNOPSIS
Runs a synthetic before/after index experiment in a disposable lab database.
.DESCRIPTION
Run setup.sql first. Creates an index in ToolkitBenchmark. Captures all raw trials and STATISTICS IO/TIME messages.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
    [string]$Instance = 'localhost,1433',
    [pscredential]$Credential,
    [ValidateRange(5,100)][int]$Trials = 10,
    [string]$OutputDirectory = './artifacts/benchmark'
)
$ErrorActionPreference = 'Stop'
if (-not $PSCmdlet.ShouldProcess($Instance, 'Benchmark and create index in ToolkitBenchmark lab database')) { return }
Import-Module (Join-Path $PSScriptRoot '../powershell/Toolkit.psm1') -Force
$connectionString = Get-ToolkitConnectionString -Instance $Instance -Database 'ToolkitBenchmark' -IntegratedSecurity ($null -eq $Credential)
$connection = [System.Data.SqlClient.SqlConnection]::new($connectionString)
$password = $null
if ($null -ne $Credential) {
    $password = $Credential.Password.Copy(); $password.MakeReadOnly()
    $connection.Credential=[System.Data.SqlClient.SqlCredential]::new($Credential.UserName,$password)
}
$messages = [System.Collections.Generic.List[string]]::new()
$handler = [System.Data.SqlClient.SqlInfoMessageEventHandler]{ param($sender,$eventArgs) $messages.Add($eventArgs.Message) }
$connection.add_InfoMessage($handler)
$command = $connection.CreateCommand(); $command.CommandTimeout=120
$runDirectory = Join-Path $OutputDirectory ([guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $runDirectory -Force)
$results = [System.Collections.Generic.List[object]]::new()
function Invoke-BenchmarkSample {
    # Drain the reader so SQL's trailing STATISTICS IO/TIME messages are delivered.
    $reader = $command.ExecuteReader()
    $count = $null
    try {
        do {
            while ($reader.Read()) {
                if ($null -eq $count -and $reader.FieldCount -gt 0) { $count = $reader.GetInt64(0) }
            }
        } while ($reader.NextResult())
    } finally { $reader.Dispose() }
    if ($null -eq $count) { throw 'Benchmark returned no count result.' }
    return [long]$count
}
try {
    $connection.Open()
    $command.CommandText="SELECT COUNT(*) FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.Workload') AND name=N'IX_Workload_bucket';"
    if ([int]$command.ExecuteScalar() -ne 0) { throw 'Index already exists. Recreate the disposable lab for a valid baseline.' }
    $command.CommandText="SELECT CONCAT(@@VERSION, CHAR(10), 'rows=', (SELECT COUNT_BIG(*) FROM dbo.Workload), '; cpu_count=', cpu_count, '; physical_memory_kb=', physical_memory_kb) FROM sys.dm_os_sys_info;"
    $environment = [string]$command.ExecuteScalar()
    foreach ($phase in @('before','after')) {
        if ($phase -eq 'after') {
            $command.CommandText='CREATE INDEX IX_Workload_bucket ON dbo.Workload(bucket);'
            [void]$command.ExecuteNonQuery()
        }
        $command.CommandText='SET STATISTICS IO ON; SET STATISTICS TIME ON; SELECT COUNT_BIG(*) FROM dbo.Workload WHERE bucket = 42 OPTION (MAXDOP 1);'
        # Two warmups per phase; no shared server cache flushing.
        1..2 | ForEach-Object { [void](Invoke-BenchmarkSample) }
        $messages.Clear()
        for ($trial=1; $trial -le $Trials; $trial++) {
            $messages.Clear()
            $watch=[System.Diagnostics.Stopwatch]::StartNew()
            $count=Invoke-BenchmarkSample
            $watch.Stop()
            if ($count -ne 100) { throw "Unexpected row count: $count" }
            $results.Add([pscustomobject]@{phase=$phase; trial=$trial; elapsed_ms=$watch.Elapsed.TotalMilliseconds; count=$count; sql_messages=@($messages.ToArray())})
        }
    }
    [pscustomobject]@{schema_version=1; collected_utc=[datetime]::UtcNow.ToString('o'); environment=$environment; runtime=$PSVersionTable.PSVersion.ToString(); os=[System.Runtime.InteropServices.RuntimeInformation]::OSDescription; trials=$results.ToArray(); limitations='Synthetic single-client warm-cache fixed-order experiment; not production throughput or toolkit overhead.'} |
        ConvertTo-Json -Depth 10 | Set-Content (Join-Path $runDirectory 'raw.json') -Encoding utf8
} finally {
    $command.Dispose(); $connection.remove_InfoMessage($handler); $connection.Dispose()
    if ($null -ne $password) { $password.Dispose() }
}
Write-Output $runDirectory
