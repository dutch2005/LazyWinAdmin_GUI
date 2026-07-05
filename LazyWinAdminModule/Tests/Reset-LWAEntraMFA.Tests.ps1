Describe 'Reset-LWAEntraMFA' {
    BeforeAll {
        if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue)) { function Get-MgContext { } }
        if (-not (Get-Command Invoke-MgGraphRequest -ErrorAction SilentlyContinue)) { function Invoke-MgGraphRequest { param($Uri) } }
        if (-not (Get-Command Test-LWAEntraRole -ErrorAction SilentlyContinue)) { function Test-LWAEntraRole { return $true } }
        if (-not (Get-Command Invoke-LWAEntraPIMElevation -ErrorAction SilentlyContinue)) { function Invoke-LWAEntraPIMElevation { return [PSCustomObject]@{Success=$true} } }
        . $PSScriptRoot\..\Public\Reset-LWAEntraMFA.ps1
    }

    Context 'When user provides justification and elevates' {
        It 'Successfully resets MFA methods' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'admin' } }
            Mock Test-LWAEntraRole { return $false }
            Mock Invoke-LWAEntraPIMElevation { return [PSCustomObject]@{ Success = $true } }
            
            Mock Invoke-MgGraphRequest {
                if ($Uri -match 'microsoftAuthenticatorMethods$') {
                    return [PSCustomObject]@{ value = @([PSCustomObject]@{ id = 'method1' }, [PSCustomObject]@{ id = 'method2' }) }
                } else {
                    return $null # DELETE response
                }
            } -ParameterFilter { $Uri -match 'authentication/microsoftAuthenticatorMethods' }

            $result = Reset-LWAEntraMFA -UserPrincipalName 'user1' -Justification 'INC1234 reset mfa'
            $result.Success | Should -Be $true
            $result.MethodsRemoved | Should -Be 2
        }
    }
}
