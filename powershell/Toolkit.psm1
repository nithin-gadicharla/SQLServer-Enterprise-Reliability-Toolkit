#Requires -Version 7.2
Set-StrictMode -Version Latest
function Invoke-ToolkitQuery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Instance,
        [Parameter(Mandatory)][string]$Sql,
        [ValidateRange(1,300)][int]$ConnectionTimeout = 10,
        [ValidateRange(1,3600)][int]$QueryTimeout = 30,
        [pscredential]$Credential
    )
    # Explicit TLS and certificate validation. Connection-string builder prevents injection.
    $connectionString = Get-ToolkitConnectionString -Instance $Instance -ConnectionTimeout $ConnectionTimeout -IntegratedSecurity ($null -eq $Credential)
    $connection = [System.Data.SqlClient.SqlConnection]::new($connectionString)
    $password = $null
    if ($null -ne $Credential) {
        $password = $Credential.Password.Copy()
        $password.MakeReadOnly()
        $connection.Credential = [System.Data.SqlClient.SqlCredential]::new($Credential.UserName, $password)
    }
    $command = $connection.CreateCommand()
    $command.CommandText = $Sql
    $command.CommandTimeout = $QueryTimeout
    $adapter = [System.Data.SqlClient.SqlDataAdapter]::new($command)
    $data = [System.Data.DataSet]::new()
    try {
        $connection.Open()
        [void]$adapter.Fill($data)
        return ,$data
    } catch {
        $data.Dispose()
        throw
    } finally {
        $adapter.Dispose()
        $command.Dispose()
        $connection.Dispose()
        if ($null -ne $password) { $password.Dispose() }
    }
}
function Get-ToolkitId {
    param([Parameter(Mandatory)][string]$Value)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
    return [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData($bytes)).Substring(0,16).ToLowerInvariant()
}
function ConvertTo-ToolkitResultSets {
    param([Parameter(Mandatory)][System.Data.DataSet]$Data)
    foreach ($table in $Data.Tables) {
        $rows = @(foreach ($row in $table.Rows) {
            $record = [ordered]@{}
            foreach ($column in $table.Columns) {
                $value = $row[$column.ColumnName]
                $record[$column.ColumnName] = if ($value -is [DBNull]) { $null } else { $value }
            }
            [pscustomobject]$record
        })
        [pscustomobject]@{columns=@($table.Columns | ForEach-Object { $_.ColumnName }); rows=$rows}
    }
}
function Get-ToolkitBackupSql {
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string[]]$BackupPaths,
        [ValidateRange(1,2147483647)][int]$Position = 1
    )
    $devices = @(
        foreach ($path in $BackupPaths) {
            if ([string]::IsNullOrWhiteSpace($path)) { throw 'Backup paths cannot be blank.' }
            "DISK = N'" + $path.Replace("'", "''") + "'"
        }
    ) -join ', '
    return "RESTORE VERIFYONLY FROM $devices WITH FILE = $Position, CHECKSUM, STOP_ON_ERROR;"
}
function Get-ToolkitConnectionString {
    param(
        [Parameter(Mandatory)][string]$Instance,
        [string]$Database = 'master',
        [bool]$IntegratedSecurity = $true,
        [ValidateRange(1,300)][int]$ConnectionTimeout = 10
    )
    $builder = [System.Data.SqlClient.SqlConnectionStringBuilder]::new()
    $builder['Data Source'] = $Instance
    $builder['Initial Catalog'] = $Database
    $builder['Integrated Security'] = $IntegratedSecurity
    $builder['Encrypt'] = $true
    $builder['TrustServerCertificate'] = $false
    $builder['Connect Timeout'] = $ConnectionTimeout
    $builder['Application Name'] = 'SQLServer-Enterprise-Reliability-Toolkit'
    return $builder.get_ConnectionString()
}
Export-ModuleMember -Function Get-ToolkitConnectionString, Invoke-ToolkitQuery, Get-ToolkitId, ConvertTo-ToolkitResultSets, Get-ToolkitBackupSql
