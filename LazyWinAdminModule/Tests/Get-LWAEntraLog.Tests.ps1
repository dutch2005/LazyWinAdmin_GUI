Describe 'Get-LWAEntraLog' {
    BeforeAll {
        if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue)) { function Get-MgContext { } }
        if (-not (Get-Command Invoke-MgGraphRequest -ErrorAction SilentlyContinue)) { function Invoke-MgGraphRequest { } }
        if (-not (Get-Command Test-LWAEntraRole -ErrorAction SilentlyContinue)) { function Test-LWAEntraRole { return $true } }
        if (-not (Get-Command Invoke-LWAEntraPIMElevation -ErrorAction SilentlyContinue)) { function Invoke-LWAEntraPIMElevation { return [PSCustomObject]@{Success=$true} } }
        . $PSScriptRoot\..\Public\Get-LWAEntraLog.ps1
    }

    Context 'When missing Graph connection' {
        It 'Throws connection error' {
            Mock Get-MgContext { return $null }
            { Get-LWAEntraLog -LogType 'SignIns' } | Should -Throw 'Not connected to Microsoft Graph.'
        }
    }

    Context 'When user lacks permissions and provides no justification' {
        It 'Throws elevation required error' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'admin' } }
            Mock Test-LWAEntraRole { return $false }
            { Get-LWAEntraLog -LogType 'SignIns' } | Should -Throw 'Active permission missing. Please provide a -Justification to elevate via PIM.'
        }
    }

    Context 'When user provides justification and elevates' {
        It 'Successfully invokes the action' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'admin' } }
            Mock Test-LWAEntraRole { return $false }
            Mock Invoke-LWAEntraPIMElevation { return [PSCustomObject]@{ Success = $true } }
            
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{ value = @('Log1', 'Log2') }
            } -ParameterFilter { $Uri -match 'auditLogs/signIns' }

            $result = Get-LWAEntraLog -LogType 'SignIns' -Justification 'INC1234 Retrieve logs'
            $result.Count | Should -Be 2
            $result[0] | Should -Be 'Log1'
        }
        
        It 'Throws if PIM elevation fails' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'admin' } }
            Mock Test-LWAEntraRole { return $false }
            Mock Invoke-LWAEntraPIMElevation { return [PSCustomObject]@{ Success = $false; Error = 'Denied' } }
            
            { Get-LWAEntraLog -LogType 'SignIns' -Justification 'INC1234 Fetch logs' } | Should -Throw 'PIM Elevation failed: Denied'
        }
    }

    Context 'When user already has active role' {
        It 'Bypasses PIM and fetches Audits' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'admin' } }
            Mock Test-LWAEntraRole { return $true }
            
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{ value = ,@('Audit1', 'Audit2') }
            } -ParameterFilter { $Uri -match 'auditLogs/directoryAudits' }

            $result = Get-LWAEntraLog -LogType 'DirectoryAudits'
            $result.Count | Should -Be 2
            $result[0] | Should -Be 'Audit1'
        }
    }
}
