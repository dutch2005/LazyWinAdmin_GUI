Describe 'Get-LWABitLockerKey' {
    BeforeAll {
        if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue)) { function Get-MgContext { } }
        if (-not (Get-Command Invoke-MgGraphRequest -ErrorAction SilentlyContinue)) { function Invoke-MgGraphRequest { } }
        if (-not (Get-Command Test-LWAEntraRole -ErrorAction SilentlyContinue)) { function Test-LWAEntraRole { return $true } }
        if (-not (Get-Command Invoke-LWAEntraPIMElevation -ErrorAction SilentlyContinue)) { function Invoke-LWAEntraPIMElevation { return [PSCustomObject]@{Success=$true} } }
        . $PSScriptRoot\..\Public\Get-LWABitLockerKey.ps1
    }

    Context 'When missing Graph connection' {
        It 'Throws connection error' {
            Mock Get-MgContext { return $null }
            { Get-LWABitLockerKey -DeviceId '123' } | Should -Throw 'Not connected to Microsoft Graph.'
        }
    }

    Context 'When user lacks permissions and provides no justification' {
        It 'Throws elevation required error' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'admin' } }
            Mock Test-LWAEntraRole { return $false }
            { Get-LWABitLockerKey -DeviceId '123' } | Should -Throw 'Active permission missing. Please provide a -Justification to elevate via PIM.'
        }
    }

    Context 'When user provides justification and elevates' {
        It 'Successfully retrieves the key' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'admin' } }
            Mock Test-LWAEntraRole { return $false }
            Mock Invoke-LWAEntraPIMElevation { return [PSCustomObject]@{ Success = $true } }
            
            Mock Invoke-MgGraphRequest {
                param($Uri)
                if ($Uri -match 'deviceId') {
                    return [PSCustomObject]@{ value = @( [PSCustomObject]@{ id = 'key1'; createdDateTime = 'now'; volumeType = 'osVolume' } ) }
                } else {
                    return [PSCustomObject]@{ key = '1111-2222-3333-4444' }
                }
            }

            $result = Get-LWABitLockerKey -DeviceId '123' -Justification 'INC1234 Need key'
            $result[0].Key | Should -Be '1111-2222-3333-4444'
        }
        
        It 'Throws if PIM elevation fails' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'admin' } }
            Mock Test-LWAEntraRole { return $false }
            Mock Invoke-LWAEntraPIMElevation { return [PSCustomObject]@{ Success = $false; Error = 'Denied' } }
            
            { Get-LWABitLockerKey -DeviceId '123' -Justification 'INC1234 Need key' } | Should -Throw 'PIM Elevation failed: Denied'
        }
    }

    Context 'When user already has active role' {
        It 'Bypasses PIM and retrieves the key' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'admin' } }
            Mock Test-LWAEntraRole { return $true }
            
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{ value = @() }
            } -ParameterFilter { $Uri -match 'deviceId' }

            $result = Get-LWABitLockerKey -DeviceId '123'
            $result | Should -BeNullOrEmpty
        }
    }
}
