#Requires -Version 7.2
<#
.SYNOPSIS
Collects read-only, versioned JSON reports, retaining every result set.
.EXAMPLE
./powershell/Invoke-SqlFleetAssessment.ps1 -Instances sql01,sql02 -OutputDirectory ./reports
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string[]]$Instances,
    [string]$OutputDirectory = './reports',
    [ValidateRange(1,300)][int]$ConnectionTimeout = 10,
    [ValidateRange(1,3600)][int]$QueryTimeout = 30,
    [pscredential]$Credential
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Toolkit.psm1') -Force
$runId = [guid]::NewGuid().ToString('N')
$runPath = Join-Path $OutputDirectory $runId
[void](New-Item -ItemType Directory -Path $runPath)
$checks = @(Get-ChildItem (Join-Path (Split-Path $PSScriptRoot -Parent) 'sql') -Filter '*.sql' | Sort-Object Name)
$summary = @(
    foreach ($instance in ($Instances | Select-Object -Unique)) {
        if ([string]::IsNullOrWhiteSpace($instance)) { throw 'Instance cannot be blank.' }
        foreach ($check in $checks) {
            $start = [datetime]::UtcNow
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            $data = $null
            $report = [ordered]@{
                schema_version = 1; toolkit_version = '0.2.0'; run_id = $runId
                instance = $instance; check = $check.Name; started_utc = $start.ToString('o')
                status = 'failed'; elapsed_ms = 0; result_sets = @(); error = $null
                query_sha256 = (Get-FileHash $check.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            }
            try {
                $arguments = @{Instance=$instance; Sql=(Get-Content $check.FullName -Raw); ConnectionTimeout=$ConnectionTimeout; QueryTimeout=$QueryTimeout}
                if ($null -ne $Credential) { $arguments.Credential = $Credential }
                $data = Invoke-ToolkitQuery @arguments
                $report.result_sets = @(ConvertTo-ToolkitResultSets -Data $data)
                $report.status = 'collected'
            } catch {
                # Do not persist exception messages: they may contain topology or authentication details.
                $report.error = [ordered]@{type=$_.Exception.GetType().FullName; message='Collection failed. Inspect locally with authorized diagnostics.'}
            } finally {
                $timer.Stop()
                $report.elapsed_ms = $timer.ElapsedMilliseconds
                if ($null -ne $data) { $data.Dispose() }
            }
            $file = '{0}_{1}.json' -f (Get-ToolkitId $instance), $check.BaseName
            $report | ConvertTo-Json -Depth 30 | Set-Content (Join-Path $runPath $file) -Encoding utf8
            [pscustomobject]@{instance=$instance; check=$check.Name; status=$report.status; elapsed_ms=$report.elapsed_ms; report=$file}
        }
    }
)
$summary | ConvertTo-Json -Depth 5 -AsArray | Set-Content (Join-Path $runPath 'summary.json') -Encoding utf8
$summary
if (@($summary | Where-Object status -eq 'failed').Count -gt 0) { exit 1 }
