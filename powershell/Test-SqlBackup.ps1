#Requires -Version 7.2
<#
.SYNOPSIS
Opt-in SQL Server disk backup readability and checksum verification. Does not restore a database.
.DESCRIPTION
Supply every stripe from one media set and the backup set position. Paths are on the SQL Server host.
Requires an account authorized for RESTORE VERIFYONLY; may generate substantial I/O.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)][string]$Instance,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string[]]$BackupPaths,
    [ValidateRange(1,2147483647)][int]$Position = 1,
    [ValidateRange(1,3600)][int]$QueryTimeout = 600,
    [pscredential]$Credential
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Toolkit.psm1') -Force
$sql = Get-ToolkitBackupSql -BackupPaths $BackupPaths -Position $Position
if ($PSCmdlet.ShouldProcess($Instance, 'Verify supplied backup media with required checksums')) {
    $arguments = @{Instance=$Instance; Sql=$sql; QueryTimeout=$QueryTimeout}
    if ($null -ne $Credential) { $arguments.Credential = $Credential }
    $data = Invoke-ToolkitQuery @arguments
    $data.Dispose()
    [pscustomobject]@{instance=$Instance; verified_utc=[datetime]::UtcNow.ToString('o'); position=$Position; stripes=$BackupPaths.Count; result='VERIFYONLY passed; restore and CHECKDB not performed'}
}
