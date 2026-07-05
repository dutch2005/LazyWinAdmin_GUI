Describe 'Revoke-LWAEntraSession' {
    BeforeAll {
        if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue)) { function Get-MgContext { } }
        if (-not (Get-Command Invoke-MgGraphRequest -ErrorAction SilentlyContinue)) { function Invoke-MgGraphRequest { } }
        if (-not (Get-Command Test-LWAEntraRole -ErrorAction SilentlyContinue)) { function Test-LWAEntraRole { return $true } }
        if (-not (Get-Command Invoke-LWAEntraPIMElevation -ErrorAction SilentlyContinue)) { function Invoke-LWAEntraPIMElevation { return [PSCustomObject]@{Success=$true} } }
        . $PSScriptRoot\..\Public\Revoke-LWAEntraSession.ps1
    }

    Context 'When user provides justification and elevates' {
        It 'Successfully revokes sessions' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'admin' } }
            Mock Test-LWAEntraRole { return $false }
            Mock Invoke-LWAEntraPIMElevation { return [PSCustomObject]@{ Success = $true } }
            
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{ value = $true }
            } -ParameterFilter { $Uri -match 'revokeSignInSessions' }

            $result = Revoke-LWAEntraSession -UserPrincipalName 'user1' -Justification 'INC1234 revoke'
            $result.Success | Should -Be $true
        }
    }
}
