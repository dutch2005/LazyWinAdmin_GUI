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
    if (-not (Get-Command Add-MailboxPermission -ErrorAction SilentlyContinue)) {
        function Add-MailboxPermission { param([string]$Identity, [string]$User, [string[]]$AccessRights, [string]$InheritanceType, [bool]$AutoMapping) }
    }
    if (-not (Get-Command Add-RecipientPermission -ErrorAction SilentlyContinue)) {
        function Add-RecipientPermission { param([string]$Identity, [string]$Trustee, [string[]]$AccessRights, [switch]$Confirm) }
    }

    $script:FakeMailbox = [PSCustomObject]@{
        Alias              = 'shared-mb'
        PrimarySmtpAddress = 'shared@contoso.com'
        DisplayName        = 'Shared Mailbox'
    }
}

Describe 'Set-ExchangeMailboxPermission' {

    Context 'Parameter validation' {

        It 'Action parameter is mandatory — throws without it' {
            { Set-ExchangeMailboxPermission } | Should -Throw
        }

        It 'Invalid Action value throws (ValidateSet enforcement)' {
            { Set-ExchangeMailboxPermission -Action 'Delete' } | Should -Throw
        }
    }

    Context 'WhatIf support' {

        It 'Returns "[!] Skipped by -WhatIf or -Confirm." when -WhatIf is specified' {
            $result = Set-ExchangeMailboxPermission -Action 'Grant' -Mailbox 'mb@test.com' -User 'u@test.com' -WhatIf
            $result | Should -Be '[!] Skipped by -WhatIf or -Confirm.'
        }
    }

    Context 'Mirror — missing SourceUser or TargetUser' {

        It 'Returns [!] message when SourceUser is missing' {
            $result = Set-ExchangeMailboxPermission -Action 'Mirror' -TargetUser 'target@test.com'
            $result | Should -Be '[!] Mirror requires both SourceUser and TargetUser.'
        }

        It 'Returns [!] message when TargetUser is missing' {
            $result = Set-ExchangeMailboxPermission -Action 'Mirror' -SourceUser 'source@test.com'
            $result | Should -Be '[!] Mirror requires both SourceUser and TargetUser.'
        }

        It 'Returns [!] message when both SourceUser and TargetUser are missing' {
            $result = Set-ExchangeMailboxPermission -Action 'Mirror'
            $result | Should -Be '[!] Mirror requires both SourceUser and TargetUser.'
        }
    }

    Context 'Mirror — source user has permissions' {

        BeforeAll {
            Mock Get-Mailbox { @($script:FakeMailbox) }
            Mock Get-MailboxPermission {
                [PSCustomObject]@{ User = 'source@test.com'; AccessRights = @('FullAccess') }
            }
            Mock Get-RecipientPermission {
                [PSCustomObject]@{ Trustee = 'source@test.com'; AccessRights = @('SendAs') }
            }
            Mock Add-MailboxPermission { }
            Mock Add-RecipientPermission { }
        }

        It 'Returns [OK] message with count when permissions found' {
            $result = Set-ExchangeMailboxPermission -Action 'Mirror' -SourceUser 'source@test.com' -TargetUser 'target@test.com'
            $result | Should -Match '\[OK\]'
            $result | Should -BeLike '*Mirrored*permission*'
        }
    }

    Context 'Mirror — no permissions found for source user' {

        BeforeAll {
            Mock Get-Mailbox { @($script:FakeMailbox) }
            Mock Get-MailboxPermission { @() }
            Mock Get-RecipientPermission { @() }
        }

        It 'Returns [!] no permissions found message' {
            $result = Set-ExchangeMailboxPermission -Action 'Mirror' -SourceUser 'noone@test.com' -TargetUser 'target@test.com'
            $result | Should -Match '\[!\]'
            $result | Should -BeLike '*No shared mailbox permissions found*'
        }
    }

    Context 'Grant — missing Mailbox or User' {

        It 'Returns [!] message when Mailbox is missing' {
            $result = Set-ExchangeMailboxPermission -Action 'Grant' -User 'user@test.com'
            $result | Should -Be '[!] Grant requires both Mailbox and User.'
        }

        It 'Returns [!] message when User is missing' {
            $result = Set-ExchangeMailboxPermission -Action 'Grant' -Mailbox 'mb@test.com'
            $result | Should -Be '[!] Grant requires both Mailbox and User.'
        }
    }

    Context 'Grant — success' {

        BeforeAll {
            Mock Add-MailboxPermission { }
            Mock Add-RecipientPermission { }
        }

        It 'Returns [OK] message confirming grant' {
            $result = Set-ExchangeMailboxPermission -Action 'Grant' -Mailbox 'mailbox@test.com' -User 'user@test.com'
            $result | Should -Be '[OK] Granted FullAccess and SendAs on mailbox@test.com to user@test.com'
        }
    }

    Context 'Error path' {

        BeforeAll {
            Mock Get-Mailbox { throw 'Exchange connection lost' }
        }

        It 'Returns [!] operation failed message when Get-Mailbox throws' {
            $result = Set-ExchangeMailboxPermission -Action 'Mirror' -SourceUser 'src@test.com' -TargetUser 'tgt@test.com'
            $result | Should -Match '\[!\]'
            $result | Should -BeLike '*Operation failed*'
        }
    }
}