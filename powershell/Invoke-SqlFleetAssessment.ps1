#Requires -Version 5.1
<#[.SYNOPSIS] Runs read-only SQL diagnostics against a supplied instance list.
.DESCRIPTION Uses Invoke-Sqlcmd from the SqlServer PowerShell module. No credentials are stored.
.EXAMPLE .\Invoke-SqlFleetAssessment.ps1 -Instances 'sql01','sql02' -OutputDirectory .\reports
#>
[CmdletBinding()]
param(
 [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string[]]$Instances,
 [string]$OutputDirectory = './reports',
 [int]$ConnectionTimeout = 10,
 [int]$QueryTimeout = 30
)
$ErrorActionPreference = 'Stop'
Import-Module SqlServer -ErrorAction Stop
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$sqlDirectory = Join-Path (Split-Path -Parent $PSScriptRoot) 'sql'
$queries = Get-ChildItem -Path $sqlDirectory -Filter '*.sql' | Sort-Object Name
$summary = foreach ($instance in $Instances) {
 foreach ($query in $queries) {
  $safeInstance = $instance -replace '[^a-zA-Z0-9_.-]','_'
  $baseName = '{0}_{1}' -f $safeInstance,$query.BaseName
  try {
   $rows = @(Invoke-Sqlcmd -ServerInstance $instance -InputFile $query.FullName -ConnectionTimeout $ConnectionTimeout -QueryTimeout $QueryTimeout -ErrorAction Stop)
   $rows | Export-Csv -Path (Join-Path $OutputDirectory "$baseName.csv") -NoTypeInformation
   [pscustomobject]@{ Instance=$instance; Check=$query.Name; Status='Success'; RowCount=$rows.Count; Error='' }
  } catch {
   [pscustomobject]@{ Instance=$instance; Check=$query.Name; Status='Failed'; RowCount=0; Error=$_.Exception.Message }
  }
 }
}
$summary | Export-Csv -Path (Join-Path $OutputDirectory 'assessment-summary.csv') -NoTypeInformation
$summary
