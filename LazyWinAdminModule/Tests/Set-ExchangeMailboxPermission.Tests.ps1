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

    Context 'Parameter set enforcement' {

        # The parameter binder enforces required combinations. Missing or mixed
        # parameters now throw ParameterBindingException before the function body
        # runs — no manual validation needed inside the function.

        It 'Throws when called with no parameters (no parameter set resolves)' {
            { Set-ExchangeMailboxPermission } | Should -Throw
        }

        It 'Mirror set: throws when only SourceUser is provided (TargetUser missing)' {
            { Set-ExchangeMailboxPermission -SourceUser 'src@test.com' } | Should -Throw
        }

        It 'Mirror set: throws when only TargetUser is provided (SourceUser missing)' {
            { Set-ExchangeMailboxPermission -TargetUser 'tgt@test.com' } | Should -Throw
        }

        It 'Grant set: throws when only Mailbox is provided (User missing)' {
            { Set-ExchangeMailboxPermission -Mailbox 'mb@test.com' } | Should -Throw
        }

        It 'Grant set: throws when only User is provided (Mailbox missing)' {
            { Set-ExchangeMailboxPermission -User 'user@test.com' } | Should -Throw
        }

        It 'Throws when mixing Mirror and Grant parameters' {
            { Set-ExchangeMailboxPermission -SourceUser 'src' -Mailbox 'mb' } | Should -Throw
        }

        It 'Rejects empty-string SourceUser via ValidateNotNullOrEmpty' {
            { Set-ExchangeMailboxPermission -SourceUser '' -TargetUser 'tgt' } | Should -Throw
        }

        It 'Rejects empty-string Mailbox via ValidateNotNullOrEmpty' {
            { Set-ExchangeMailboxPermission -Mailbox '' -User 'u' } | Should -Throw
        }
    }

    Context 'WhatIf support' {

        It 'Grant set: -WhatIf returns skip message' {
            $result = Set-ExchangeMailboxPermission -Mailbox 'mb@test.com' -User 'u@test.com' -WhatIf
            $result | Should -Be '[!] Skipped by -WhatIf or -Confirm.'
        }

        It 'Mirror set: -WhatIf returns skip message' {
            $result = Set-ExchangeMailboxPermission -SourceUser 'src@test.com' -TargetUser 'tgt@test.com' -WhatIf
            $result | Should -Be '[!] Skipped by -WhatIf or -Confirm.'
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
            $result = Set-ExchangeMailboxPermission -SourceUser 'source@test.com' -TargetUser 'target@test.com'
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
            $result = Set-ExchangeMailboxPermission -SourceUser 'noone@test.com' -TargetUser 'target@test.com'
            $result | Should -Match '\[!\]'
            $result | Should -BeLike '*No shared mailbox permissions found*'
        }
    }

    Context 'Grant — success' {

        BeforeAll {
            Mock Add-MailboxPermission { }
            Mock Add-RecipientPermission { }
        }

        It 'Returns [OK] message confirming grant' {
            $result = Set-ExchangeMailboxPermission -Mailbox 'mailbox@test.com' -User 'user@test.com'
            $result | Should -Be '[OK] Granted FullAccess and SendAs on mailbox@test.com to user@test.com'
        }
    }

    Context 'Error path' {

        BeforeAll {
            Mock Get-Mailbox { throw 'Exchange connection lost' }
        }

        It 'Returns [!] operation failed message when Get-Mailbox throws' {
            $result = Set-ExchangeMailboxPermission -SourceUser 'src@test.com' -TargetUser 'tgt@test.com'
            $result | Should -Match '\[!\]'
            $result | Should -BeLike '*Operation failed*'
        }
    }
}
