function Convert-ExchangeMailbox {
    <#
    .SYNOPSIS
        Converts a mailbox between Regular, Shared, Room and Equipment types.
    .DESCRIPTION
        Wraps Set-Mailbox -Type. Converting a leaver's mailbox to Shared is the standard
        way to retain their mail without a paid license. Relies on the caller having an
        active Exchange session.
    .PARAMETER Mailbox
        Primary SMTP address or alias of the mailbox.
    .PARAMETER Type
        Target type: Shared, Regular, Room or Equipment.
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
        [ValidateSet('Shared', 'Regular', 'Room', 'Equipment')]
        [string]$Type
    )

    if (-not $PSCmdlet.ShouldProcess($Mailbox, "Convert mailbox to $Type")) {
        return '[!] Skipped by -WhatIf or -Confirm.'
    }

    try {
        Set-Mailbox -Identity $Mailbox -Type $Type -ErrorAction Stop | Out-Null
        return "[OK] Converted $Mailbox to a $Type mailbox"
    }
    catch {
        Write-Warning "Mailbox conversion failed: $_"
        return '[!] Mailbox conversion failed. Verify the Exchange connection and mailbox.'
    }
}
