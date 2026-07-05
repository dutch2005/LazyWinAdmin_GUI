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

    # Stubs for Exchange cmdlets
    if (-not (Get-Command Get-Mailbox -ErrorAction SilentlyContinue)) {
        function Get-Mailbox { param([string]$RecipientTypeDetails, [string]$Identity) }
    }
    if (-not (Get-Command Get-MailboxPermission -ErrorAction SilentlyContinue)) {
        function Get-MailboxPermission { param([string]$Identity) }
    }
    if (-not (Get-Command Get-RecipientPermission -ErrorAction SilentlyContinue)) {
        function Get-RecipientPermission { param([string]$Identity) }
    }

    $script:FakeMailbox = [PSCustomObject]@{
        Alias            = 'shared-mb'
        PrimarySmtpAddress = 'shared@contoso.com'
        DisplayName      = 'Shared Mailbox'
    }
}

Describe 'Get-ExchangeMailboxPermission' {

    Context 'Parameter validation' {

        It 'UserPrincipalName is mandatory — throws without it' {
            { Get-ExchangeMailboxPermission } | Should -Throw
        }
    }

    Context 'User with FullAccess only' {

        BeforeAll {
            Mock Get-Mailbox { @($script:FakeMailbox) }
            Mock Get-MailboxPermission {
                [PSCustomObject]@{ User = 'user@contoso.com'; AccessRights = @('FullAccess') }
            }
            Mock Get-RecipientPermission { @() }
        }

        It 'Returns result with FullAccess=$true and SendAs=$false' {
            $result = Get-ExchangeMailboxPermission -UserPrincipalName 'user@contoso.com'
            $result | Should -Not -BeNullOrEmpty
            $result.FullAccess | Should -BeTrue
            $result.SendAs     | Should -BeFalse
        }
    }

    Context 'User with SendAs only' {

        BeforeAll {
            Mock Get-Mailbox { @($script:FakeMailbox) }
            Mock Get-MailboxPermission { @() }
            Mock Get-RecipientPermission {
                [PSCustomObject]@{ Trustee = 'user@contoso.com'; AccessRights = @('SendAs') }
            }
        }

        It 'Returns result with FullAccess=$false and SendAs=$true' {
            $result = Get-ExchangeMailboxPermission -UserPrincipalName 'user@contoso.com'
            $result | Should -Not -BeNullOrEmpty
            $result.FullAccess | Should -BeFalse
            $result.SendAs     | Should -BeTrue
        }
    }

    Context 'User with both FullAccess and SendAs' {

        BeforeAll {
            Mock Get-Mailbox { @($script:FakeMailbox) }
            Mock Get-MailboxPermission {
                [PSCustomObject]@{ User = 'user@contoso.com'; AccessRights = @('FullAccess') }
            }
            Mock Get-RecipientPermission {
                [PSCustomObject]@{ Trustee = 'user@contoso.com'; AccessRights = @('SendAs') }
            }
        }

        It 'Returns result with FullAccess=$true and SendAs=$true' {
            $result = Get-ExchangeMailboxPermission -UserPrincipalName 'user@contoso.com'
            $result | Should -Not -BeNullOrEmpty
            $result.FullAccess | Should -BeTrue
            $result.SendAs     | Should -BeTrue
        }
    }

    Context 'User with no permissions' {

        BeforeAll {
            Mock Get-Mailbox { @($script:FakeMailbox) }
            Mock Get-MailboxPermission { @() }
            Mock Get-RecipientPermission { @() }
        }

        It 'Returns empty list when user has no permissions on any mailbox' {
            $result = Get-ExchangeMailboxPermission -UserPrincipalName 'noone@contoso.com'
            @($result).Count | Should -Be 0
        }
    }

    Context 'Result object shape' {

        BeforeAll {
            Mock Get-Mailbox { @($script:FakeMailbox) }
            Mock Get-MailboxPermission {
                [PSCustomObject]@{ User = 'user@contoso.com'; AccessRights = @('FullAccess') }
            }
            Mock Get-RecipientPermission { @() }
        }

        It 'Result objects have Mailbox, DisplayName, FullAccess, SendAs properties' {
            $result = Get-ExchangeMailboxPermission -UserPrincipalName 'user@contoso.com'
            $obj    = $result | Select-Object -First 1
            $obj.PSObject.Properties.Name | Should -Contain 'Mailbox'
            $obj.PSObject.Properties.Name | Should -Contain 'DisplayName'
            $obj.PSObject.Properties.Name | Should -Contain 'FullAccess'
            $obj.PSObject.Properties.Name | Should -Contain 'SendAs'
        }
    }

    Context 'Error path' {

        BeforeAll {
            Mock Get-Mailbox { throw 'Exchange connection lost' }
        }

        It 'Returns $null when Get-Mailbox throws' {
            $result = Get-ExchangeMailboxPermission -UserPrincipalName 'user@contoso.com'
            $result | Should -BeNullOrEmpty
        }
    }
}