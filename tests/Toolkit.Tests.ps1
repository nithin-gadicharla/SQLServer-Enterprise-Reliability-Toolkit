BeforeAll {
    $root = Split-Path $PSScriptRoot -Parent
    Import-Module (Join-Path $root 'powershell/Toolkit.psm1') -Force
}
Describe 'PowerShell source' {
    It 'parses every script and module' {
        foreach ($file in Get-ChildItem $root -Recurse -Include *.ps1,*.psm1) {
            $tokens = $null; $errors = $null
            [void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
            $errors.Count | Should -Be 0 -Because $file.FullName
        }
    }
}
Describe 'Report identity' {
    It 'is deterministic with a known SHA-256 prefix' {
        Get-ToolkitId 'abc' | Should -Be 'ba7816bf8f01cfea'
    }
    It 'separates names which legacy filename sanitization collided' {
        (Get-ToolkitId 'host\instance') | Should -Not -Be (Get-ToolkitId 'host/instance')
    }
}
Describe 'Backup verification preview' {
    It 'does not connect in WhatIf mode, including quoted paths' {
        $result = & (Join-Path $root 'powershell/Test-SqlBackup.ps1') -Instance 'invalid' -BackupPaths "C:\O'Brien.bak" -WhatIf
        $result | Should -BeNullOrEmpty
    }
}
Describe 'Failure reporting' {
    It 'exits nonzero, records every failed check, and redacts messages' {
        $outputPath = Join-Path $TestDrive 'failure'
        & pwsh -NoProfile -File (Join-Path $root 'powershell/Invoke-SqlFleetAssessment.ps1') -Instances 'tcp:127.0.0.1,1' -ConnectionTimeout 1 -QueryTimeout 1 -OutputDirectory $outputPath | Out-Null
        $LASTEXITCODE | Should -Be 1
        $run = @(Get-ChildItem $outputPath -Directory)
        $run.Count | Should -Be 1
        $summary = @(Get-Content (Join-Path $run[0].FullName 'summary.json') -Raw | ConvertFrom-Json)
        $summary.Count | Should -Be 5
        @($summary | Where-Object status -ne 'failed').Count | Should -Be 0
        foreach ($item in $summary) {
            $report = Get-Content (Join-Path $run[0].FullName $item.report) -Raw | ConvertFrom-Json
            $report.schema_version | Should -Be 1
            $report.error.message | Should -Be 'Collection failed. Inspect locally with authorized diagnostics.'
            $report.query_sha256 | Should -Match '^[0-9a-f]{64}$'
        }
    }
}
Describe 'Heterogeneous result serialization' {
    It 'retains null values, empty schemas, and all result sets in JSON' {
        $data = [System.Data.DataSet]::new()
        $one = $data.Tables.Add('one')
        [void]$one.Columns.Add('count', [int]); [void]$one.Columns.Add('missing', [string])
        [void]$one.Rows.Add(42, [DBNull]::Value)
        $two = $data.Tables.Add('two'); [void]$two.Columns.Add('label', [string])
        $sets = @(ConvertTo-ToolkitResultSets $data)
        $json = [pscustomobject]@{result_sets=$sets} | ConvertTo-Json -Depth 10 | ConvertFrom-Json
        $json.result_sets.Count | Should -Be 2
        $json.result_sets[0].rows[0].count | Should -Be 42
        $json.result_sets[0].rows[0].missing | Should -BeNullOrEmpty
        $json.result_sets[1].columns[0] | Should -Be 'label'
        $json.result_sets[1].rows.Count | Should -Be 0
        $data.Dispose()
    }
}
Describe 'Backup SQL construction' {
    It 'quotes all stripes and requires checksums with fail-fast behavior' {
        Get-ToolkitBackupSql -BackupPaths "C:\O'Brien.bak",'D:\stripe2.bak' -Position 3 |
            Should -Be "RESTORE VERIFYONLY FROM DISK = N'C:\O''Brien.bak', DISK = N'D:\stripe2.bak' WITH FILE = 3, CHECKSUM, STOP_ON_ERROR;"
    }
    It 'rejects blank media and invalid backup positions' {
        { Get-ToolkitBackupSql -BackupPaths ' ' } | Should -Throw
        { Get-ToolkitBackupSql -BackupPaths 'a.bak' -Position 0 } | Should -Throw
    }
}
Describe 'Connection construction' {
    It 'sets canonical TLS and timeout keys without storing credentials' {
        $text = Get-ToolkitConnectionString -Instance 'sql01' -ConnectionTimeout 7 -IntegratedSecurity $false
        $builder = [System.Data.SqlClient.SqlConnectionStringBuilder]::new($text)
        $builder.get_DataSource() | Should -Be 'sql01'
        $builder.get_Encrypt() | Should -BeTrue
        $builder.get_TrustServerCertificate() | Should -BeFalse
        $builder.get_IntegratedSecurity() | Should -BeFalse
        $builder.get_ConnectTimeout() | Should -Be 7
        $builder.get_Password() | Should -BeNullOrEmpty
    }
    It 'quotes an instance value instead of accepting connection-string injection' {
        $text = Get-ToolkitConnectionString -Instance 'host;TrustServerCertificate=true'
        $builder = [System.Data.SqlClient.SqlConnectionStringBuilder]::new($text)
        $builder.get_DataSource() | Should -Be 'host;TrustServerCertificate=true'
        $builder.get_TrustServerCertificate() | Should -BeFalse
    }
}
