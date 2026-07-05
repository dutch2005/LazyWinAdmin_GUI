function Set-ExchangeAutoReply {
    <#
    .SYNOPSIS
        Enables or disables the automatic reply (Out of Office) for a mailbox.
    .DESCRIPTION
        Wraps Set-MailboxAutoReplyConfiguration. When enabling, an internal and/or
        external message may be supplied; supplying an external message also sets the
        external audience to All. Returns a status string and never surfaces exception
        detail. Relies on the caller having an active Exchange session.
    .PARAMETER Mailbox
        Primary SMTP address or alias of the mailbox.
    .PARAMETER State
        Enabled or Disabled.
    .PARAMETER InternalMessage
        Auto-reply text shown to internal senders.
    .PARAMETER ExternalMessage
        Auto-reply text shown to external senders.
    .OUTPUTS
        Status string.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Mailbox,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Enabled', 'Disabled')]
        [string]$State,

        [string]$InternalMessage,

        [string]$ExternalMessage
    )

    if (-not $PSCmdlet.ShouldProcess($Mailbox, "Set auto-reply $State")) {
        return '[!] Skipped by -WhatIf or -Confirm.'
    }

    try {
        $params = @{ Identity = $Mailbox; AutoReplyState = $State; ErrorAction = 'Stop' }
        if ($InternalMessage) { $params.InternalMessage = $InternalMessage }
        if ($ExternalMessage) {
            $params.ExternalMessage  = $ExternalMessage
            $params.ExternalAudience = 'All'
        }
        Set-MailboxAutoReplyConfiguration @params | Out-Null
        return "[OK] Auto-reply $State for $Mailbox"
    }
    catch {
        Write-Warning "Auto-reply update failed: $_"
        return '[!] Auto-reply update failed. Verify the Exchange connection and mailbox.'
    }
}
