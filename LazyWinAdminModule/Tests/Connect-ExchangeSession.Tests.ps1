#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingComputerNameHardcoded', '',
    Justification = 'Test fixtures require hardcoded computer names as test inputs.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Mock stub functions declare params to match real signatures.')]
param()

BeforeAll {
    $script:ModuleRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    Get-ChildItem (Join-Path $script:ModuleRoot 'Classes') -Filter '*.ps1' | ForEach-Object { . $_.FullName }
    Get-ChildItem (Join-Path $script:ModuleRoot 'Private') -Filter '*.ps1' | ForEach-Object { . $_.FullName }
    Get-ChildItem (Join-Path $script:ModuleRoot 'Public')  -Filter '*.ps1' | ForEach-Object { . $_.FullName }

    # Stubs for Exchange cmdlets that may not be present on test machine
    if (-not (Get-Command Connect-ExchangeOnline -ErrorAction SilentlyContinue)) {
        function Connect-ExchangeOnline { param([bool]$ShowBanner, [string]$UserPrincipalName, [string]$DelegatedOrganization, [switch]$SkipLoadingFormatData) }
    }
    if (-not (Get-Command Get-OrganizationConfig -ErrorAction SilentlyContinue)) {
        function Get-OrganizationConfig { param() }
    }
    if (-not (Get-Command Disconnect-ExchangeOnline -ErrorAction SilentlyContinue)) {
        function Disconnect-ExchangeOnline { param([switch]$Confirm) }
    }
    if (-not (Get-Command Assert-ModuleRequirement -ErrorAction SilentlyContinue)) {
        function Assert-ModuleRequirement { param([string]$ModuleName, [string]$MinimumVersion) return $true }
    }
}

Describe 'Connect-ExchangeSession' {

    Context 'Module not found' {

        BeforeAll {
            Mock Assert-ModuleRequirement { throw "ExchangeOnlineManagement module not found." } -ParameterFilter { $ModuleName -eq 'ExchangeOnlineManagement' }
        }

        It 'Returns [!] message when ExchangeOnlineManagement module is not available' {
            $result = Connect-ExchangeSession
            $result | Should -BeLike '*ExchangeOnlineManagement module not found*'
        }

        It 'Return value starts with [!]' {
            $result = Connect-ExchangeSession
            $result | Should -Match '^\[!\]'
        }
    }

    Context 'Successful connection' {

        BeforeAll {
            Mock Assert-ModuleRequirement { return $true } -ParameterFilter { $ModuleName -eq 'ExchangeOnlineManagement' }
            Mock Get-Module {
                [PSCustomObject]@{ Name = 'ExchangeOnlineManagement'; Version = '3.0.0' }
            } -ParameterFilter { $Name -eq 'ExchangeOnlineManagement' -and $ListAvailable }
            Mock Import-Module { }
            Mock Connect-ExchangeOnline { }
            Mock Get-OrganizationConfig {
                [PSCustomObject]@{ DisplayName = 'Contoso' }
            }
        }

        It 'Returns [OK] message with org display name on success' {
            $result = Connect-ExchangeSession
            $result | Should -Be '[OK] Connected to Exchange Online: Contoso'
        }

        It 'Return value starts with [OK]' {
            $result = Connect-ExchangeSession
            $result | Should -Match '^\[OK\]'
        }

        It 'Accepts -UserPrincipalName parameter without throwing' {
            { Connect-ExchangeSession -UserPrincipalName 'admin@contoso.com' } | Should -Not -Throw
        }

        It 'Forwards -DelegatedOrganization to Connect-ExchangeOnline for a customer tenant' {
            Connect-ExchangeSession -UserPrincipalName 'admin@data4.nl' -DelegatedOrganization 'customer.onmicrosoft.com' | Out-Null
            Should -Invoke Connect-ExchangeOnline -Times 1 -Exactly -ParameterFilter {
                $DelegatedOrganization -eq 'customer.onmicrosoft.com'
            }
        }

        It 'Does NOT pass DelegatedOrganization when connecting to the home tenant' {
            Connect-ExchangeSession -UserPrincipalName 'admin@data4.nl' | Out-Null
            Should -Invoke Connect-ExchangeOnline -Times 1 -Exactly -ParameterFilter {
                [string]::IsNullOrEmpty($DelegatedOrganization)
            }
        }
    }

    Context 'Connection failure' {

        BeforeAll {
            Mock Assert-ModuleRequirement { return $true } -ParameterFilter { $ModuleName -eq 'ExchangeOnlineManagement' }
            Mock Get-Module {
                [PSCustomObject]@{ Name = 'ExchangeOnlineManagement'; Version = '3.0.0' }
            } -ParameterFilter { $Name -eq 'ExchangeOnlineManagement' -and $ListAvailable }
            Mock Import-Module { }
            Mock Connect-ExchangeOnline { throw 'Authentication failed: invalid credentials' }
        }

        It 'Returns [!] generic failure message when connection throws' {
            $result = Connect-ExchangeSession
            $result | Should -BeLike '*Connection failed*'
        }

        It 'Return value does NOT contain exception detail when connection fails' {
            $result = Connect-ExchangeSession
            $result | Should -Not -Match 'Authentication failed'
            $result | Should -Not -Match 'invalid credentials'
            $result | Should -Not -Match 'Exception'
        }
    }
}