#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Mock stub functions declare params to match real cmdlet signatures.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseShouldProcessForStateChangingFunctions', '',
    Justification = 'Stub functions emulate real Exchange cmdlet names for mocking; they perform no work.')]
param()

BeforeAll {
    $script:ModuleRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    Get-ChildItem (Join-Path $script:ModuleRoot 'Classes') -Filter '*.ps1' | ForEach-Object { . $_.FullName }
    Get-ChildItem (Join-Path $script:ModuleRoot 'Private') -Filter '*.ps1' | ForEach-Object { . $_.FullName }
    Get-ChildItem (Join-Path $script:ModuleRoot 'Public')  -Filter '*.ps1' | ForEach-Object { . $_.FullName }

    if (-not (Get-Command Set-MailboxAutoReplyConfiguration -ErrorAction SilentlyContinue)) {
        function Set-MailboxAutoReplyConfiguration { param([string]$Identity, [string]$AutoReplyState, [string]$InternalMessage, [string]$ExternalMessage, [string]$ExternalAudience) }
    }
    if (-not (Get-Command Set-Mailbox -ErrorAction SilentlyContinue)) {
        function Set-Mailbox { param([string]$Identity, $ForwardingSmtpAddress, [bool]$DeliverToMailboxAndForward, [string]$Type) }
    }
}

Describe 'Set-ExchangeAutoReply' {

    Context 'WhatIf' {
        It 'Skips under -WhatIf' {
            Mock Set-MailboxAutoReplyConfiguration { }
            Set-ExchangeAutoReply -Mailbox 'm@t.com' -State Enabled -WhatIf | Should -BeLike '*Skipped by -WhatIf*'
            Should -Invoke Set-MailboxAutoReplyConfiguration -Times 0
        }
    }

    Context 'Enable with messages' {
        BeforeAll { Mock Set-MailboxAutoReplyConfiguration { } }
        It 'Sets AutoReplyState=Enabled and external audience All when an external message is given' {
            $r = Set-ExchangeAutoReply -Mailbox 'm@t.com' -State Enabled -InternalMessage 'gone' -ExternalMessage 'away'
            $r | Should -Match '^\[OK\]'
            Should -Invoke Set-MailboxAutoReplyConfiguration -Times 1 -Exactly -ParameterFilter {
                $AutoReplyState -eq 'Enabled' -and $ExternalAudience -eq 'All'
            }
        }
    }

    Context 'Failure' {
        BeforeAll { Mock Set-MailboxAutoReplyConfiguration { throw 'Exchange connection lost' } }
        It 'Returns sanitised [!]' {
            $r = Set-ExchangeAutoReply -Mailbox 'm@t.com' -State Enabled
            $r | Should -Match '^\[!\]'
            $r | Should -Not -Match 'connection lost'
        }
    }
}

Describe 'Set-ExchangeForwarding' {

    Context 'Set forwarding' {
        BeforeAll { Mock Set-Mailbox { } }
        It 'Passes the forwarding address to Set-Mailbox' {
            $r = Set-ExchangeForwarding -Mailbox 'm@t.com' -ForwardingSmtpAddress 'boss@t.com'
            $r | Should -Match '^\[OK\]'
            Should -Invoke Set-Mailbox -Times 1 -Exactly -ParameterFilter { $ForwardingSmtpAddress -eq 'boss@t.com' }
        }
    }

    Context 'Clear forwarding' {
        BeforeAll { Mock Set-Mailbox { } }
        It 'Clears forwarding when the address is empty' {
            $r = Set-ExchangeForwarding -Mailbox 'm@t.com' -ForwardingSmtpAddress ''
            $r | Should -BeLike '*Forwarding cleared*'
            Should -Invoke Set-Mailbox -Times 1 -Exactly -ParameterFilter { $null -eq $ForwardingSmtpAddress }
        }
    }
}

Describe 'Convert-ExchangeMailbox' {

    Context 'Convert to shared' {
        BeforeAll { Mock Set-Mailbox { } }
        It 'Calls Set-Mailbox -Type Shared' {
            $r = Convert-ExchangeMailbox -Mailbox 'm@t.com' -Type Shared
            $r | Should -Match '^\[OK\]'
            Should -Invoke Set-Mailbox -Times 1 -Exactly -ParameterFilter { $Type -eq 'Shared' }
        }
    }

    Context 'WhatIf' {
        It 'Skips under -WhatIf' {
            Mock Set-Mailbox { }
            Convert-ExchangeMailbox -Mailbox 'm@t.com' -Type Shared -WhatIf | Should -BeLike '*Skipped by -WhatIf*'
            Should -Invoke Set-Mailbox -Times 0
        }
    }

    Context 'Rejects an invalid type' {
        It 'Throws on an out-of-set type' {
            { Convert-ExchangeMailbox -Mailbox 'm@t.com' -Type 'Bogus' } | Should -Throw
        }
    }
}
