Describe 'Invoke-LWAIntuneAction' {
    BeforeAll {
        if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue)) { function Get-MgContext { } }
        if (-not (Get-Command Invoke-MgGraphRequest -ErrorAction SilentlyContinue)) { function Invoke-MgGraphRequest { } }
        if (-not (Get-Command Test-LWAEntraRole -ErrorAction SilentlyContinue)) { function Test-LWAEntraRole { return $true } }
        if (-not (Get-Command Invoke-LWAEntraPIMElevation -ErrorAction SilentlyContinue)) { function Invoke-LWAEntraPIMElevation { return [PSCustomObject]@{Success=$true} } }
        . $PSScriptRoot\..\Public\Invoke-LWAIntuneAction.ps1
    }

    Context 'When missing Graph connection' {
        It 'Throws connection error' {
            Mock Get-MgContext { return $null }
            { Invoke-LWAIntuneAction -DeviceId '123' -Action 'syncDevice' } | Should -Throw 'Not connected to Microsoft Graph.'
        }
    }

    Context 'When user lacks permissions and provides no justification' {
        It 'Throws elevation required error' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'admin' } }
            Mock Test-LWAEntraRole { return $false }
            { Invoke-LWAIntuneAction -DeviceId '123' -Action 'syncDevice' } | Should -Throw 'Active permission missing. Please provide a -Justification to elevate via PIM.'
        }
    }

    Context 'When user provides justification and elevates' {
        It 'Successfully invokes the action' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'admin' } }
            Mock Test-LWAEntraRole { return $false }
            Mock Invoke-LWAEntraPIMElevation { return [PSCustomObject]@{ Success = $true } }
            
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{ '@odata.context' = '...' }
            }

            $result = Invoke-LWAIntuneAction -DeviceId '123' -Action 'syncDevice' -Justification 'INC1234 Sync device'
            $result.Success | Should -Be $true
            $result.Action | Should -Be 'syncDevice'
        }
        
        It 'Throws if PIM elevation fails' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'admin' } }
            Mock Test-LWAEntraRole { return $false }
            Mock Invoke-LWAEntraPIMElevation { return [PSCustomObject]@{ Success = $false; Error = 'Denied' } }
            
            { Invoke-LWAIntuneAction -DeviceId '123' -Action 'syncDevice' -Justification 'INC1234 Sync device' } | Should -Throw 'PIM Elevation failed: Denied'
        }
    }

    Context 'When user already has active role' {
        It 'Bypasses PIM and executes wipe' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'admin' } }
            Mock Test-LWAEntraRole { return $true }
            
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{ '@odata.context' = '...' }
            }

            $result = Invoke-LWAIntuneAction -DeviceId '123' -Action 'wipe'
            $result.Success | Should -Be $true
            $result.Action | Should -Be 'wipe'
        }
    }
}
