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

    # Stubs for Microsoft Graph cmdlets if Graph module is not installed on CI runner
    if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue)) {
        function Get-MgContext { param() }
    }
    if (-not (Get-Command Invoke-MgGraphRequest -ErrorAction SilentlyContinue)) {
        function Invoke-MgGraphRequest { param([string]$Method, [string]$Uri) }
    }

    $script:FakeScripts = @(
        [PSCustomObject]@{
            id                  = 'script-001'
            displayName         = 'Configure Audit Policy'
            fileName            = 'ConfigureAudit.ps1'
            runAsAccount        = 'system'
            enforcementType     = 'required'
            createdDateTime     = '2024-01-01T00:00:00Z'
            lastModifiedDateTime = '2024-06-01T00:00:00Z'
        },
        [PSCustomObject]@{
            id                  = 'script-002'
            displayName         = 'Install Chrome'
            fileName            = 'InstallChrome.ps1'
            runAsAccount        = 'user'
            enforcementType     = 'required'
            createdDateTime     = '2024-02-01T00:00:00Z'
            lastModifiedDateTime = '2024-06-15T00:00:00Z'
        }
    )
}

Describe 'Get-IntuneManagementScript' {

    Context 'Guard — not connected to Graph' {

        BeforeAll {
            Mock Get-MgContext { return $null }
        }

        It 'Returns $null when Get-MgContext returns null' {
            $result = Get-IntuneManagementScript
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Connected — returns script objects' {

        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 'fake-tenant' } }
            Mock Invoke-MgGraphRequest { [PSCustomObject]@{ value = $script:FakeScripts } }
        }

        It 'Returns a non-null list of scripts' {
            $result = Get-IntuneManagementScript
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Returns the correct number of scripts' {
            $result = Get-IntuneManagementScript
            @($result).Count | Should -Be 2
        }
    }

    Context 'Script object shape' {

        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 'fake-tenant' } }
            Mock Invoke-MgGraphRequest { [PSCustomObject]@{ value = $script:FakeScripts } }
        }

        It 'Script objects have expected properties' {
            $result = Get-IntuneManagementScript
            $obj    = $result | Select-Object -First 1
            $obj.PSObject.Properties.Name | Should -Contain 'Id'
            $obj.PSObject.Properties.Name | Should -Contain 'DisplayName'
            $obj.PSObject.Properties.Name | Should -Contain 'FileName'
            $obj.PSObject.Properties.Name | Should -Contain 'RunAs'
            $obj.PSObject.Properties.Name | Should -Contain 'Enforcement'
            $obj.PSObject.Properties.Name | Should -Contain 'Created'
            $obj.PSObject.Properties.Name | Should -Contain 'Modified'
        }

        It 'Id property maps to script id' {
            $result = Get-IntuneManagementScript
            ($result | Where-Object { $_.Id -eq 'script-001' }) | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Search filter' {

        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 'fake-tenant' } }
            Mock Invoke-MgGraphRequest { [PSCustomObject]@{ value = $script:FakeScripts } }
        }

        It 'Search returns only matching scripts by DisplayName' {
            $result = Get-IntuneManagementScript -Search 'Audit'
            @($result).Count | Should -Be 1
            $result.DisplayName | Should -BeLike '*Audit*'
        }

        It 'Search returns only matching scripts by FileName' {
            $result = Get-IntuneManagementScript -Search 'Chrome'
            @($result).Count | Should -Be 1
            $result.FileName | Should -BeLike '*Chrome*'
        }
    }

    Context 'Empty response' {

        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 'fake-tenant' } }
            Mock Invoke-MgGraphRequest { [PSCustomObject]@{ value = @() } }
        }

        It 'Returns empty list when no scripts exist' {
            $result = Get-IntuneManagementScript
            @($result).Count | Should -Be 0
        }
    }

    Context 'Error path' {

        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 'fake-tenant' } }
            Mock Invoke-MgGraphRequest { throw 'Graph API request failed' }
        }

        It 'Returns $null when Invoke-MgGraphRequest throws' {
            $result = Get-IntuneManagementScript
            $result | Should -BeNullOrEmpty
        }
    }
}