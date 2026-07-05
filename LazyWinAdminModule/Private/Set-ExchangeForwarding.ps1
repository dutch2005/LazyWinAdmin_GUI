function Set-ExchangeForwarding {
    <#
    .SYNOPSIS
        Sets or clears SMTP forwarding on a mailbox.
    .DESCRIPTION
        Wraps Set-Mailbox. Pass an empty -ForwardingSmtpAddress to clear forwarding.
        When forwarding is set, -DeliverToMailboxAndForward controls whether a copy is
        also kept in the mailbox. Relies on the caller having an active Exchange session.
    .PARAMETER Mailbox
        Primary SMTP address or alias of the mailbox.
    .PARAMETER ForwardingSmtpAddress
        Destination SMTP address. Empty / whitespace clears forwarding.
    .PARAMETER DeliverToMailboxAndForward
        Keep a copy in the mailbox as well as forwarding. Default $true.
    .OUTPUTS
        Status string.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Mailbox,

        [string]$ForwardingSmtpAddress,

        [bool]$DeliverToMailboxAndForward = $true
    )

    if (-not $PSCmdlet.ShouldProcess($Mailbox, 'Set forwarding')) {
        return '[!] Skipped by -WhatIf or -Confirm.'
    }

    try {
        if ([string]::IsNullOrWhiteSpace($ForwardingSmtpAddress)) {
            Set-Mailbox -Identity $Mailbox -ForwardingSmtpAddress $null -ErrorAction Stop | Out-Null
            return "[OK] Forwarding cleared for $Mailbox"
        }

        Set-Mailbox -Identity $Mailbox `
            -ForwardingSmtpAddress $ForwardingSmtpAddress `
            -DeliverToMailboxAndForward $DeliverToMailboxAndForward `
            -ErrorAction Stop | Out-Null
        return "[OK] Forwarding set to $ForwardingSmtpAddress for $Mailbox"
    }
    catch {
        Write-Warning "Forwarding update failed: $_"
        return '[!] Forwarding update failed. Verify the Exchange connection and addresses.'
    }
}
