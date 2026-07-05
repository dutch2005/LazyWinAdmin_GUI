Describe 'Get-LWAExchangePermission' {
    BeforeAll {
        if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue)) { function Get-MgContext { } }
        if (-not (Get-Command Invoke-MgGraphRequest -ErrorAction SilentlyContinue)) { function Invoke-MgGraphRequest { param($Uri) } }
        if (-not (Get-Command Test-LWAEntraRole -ErrorAction SilentlyContinue)) { function Test-LWAEntraRole { return $true } }
        if (-not (Get-Command Invoke-LWAEntraPIMElevation -ErrorAction SilentlyContinue)) { function Invoke-LWAEntraPIMElevation { return [PSCustomObject]@{Success=$true} } }
        . $PSScriptRoot\..\Public\Get-LWAExchangePermission.ps1
    }

    Context 'When user provides justification and elevates' {
        It 'Successfully gets exchange settings' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'admin' } }
            Mock Test-LWAEntraRole { return $false }
            Mock Invoke-LWAEntraPIMElevation { return [PSCustomObject]@{ Success = $true } }
            
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{ value = ,@([PSCustomObject]@{ id = 'rule1' }) }
            } -ParameterFilter { $Uri -match 'messageRules' }

            $result = Get-LWAExchangePermission -UserPrincipalName 'user1' -Justification 'INC1234 get rules'
            $result.Success | Should -Be $true
            $result.InboxRules.Count | Should -Be 1
        }
    }
}
