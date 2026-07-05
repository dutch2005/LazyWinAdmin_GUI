function Set-ExchangeMailboxPermission {
    <#
    .SYNOPSIS
        Mirrors or grants mailbox permissions in Exchange Online.
    .DESCRIPTION
        Two modes, selected by parameter set:
          Mirror — copies every FullAccess, SendAs and Send-on-Behalf permission
                   held by SourceUser across all mailboxes to TargetUser. Used for
                   offboarding / role-handover scenarios. Use -SourceUser + -TargetUser.
          Grant  — grants FullAccess, SendAs and Send-on-Behalf on a single named
                   mailbox to a user. Use -Mailbox + -User.

        Parameter sets enforce the correct argument combination at bind time —
        callers cannot mix Mirror and Grant parameters in one call.

        Group memberships (distribution / Microsoft 365 / mail-enabled security
        groups) are NOT copied here — that is a separate, opt-in operation.
    .PARAMETER SourceUser
        UPN of the user whose permissions are copied (Mirror set).
    .PARAMETER TargetUser
        UPN of the user who receives the copied permissions (Mirror set).
    .PARAMETER Mailbox
        Primary SMTP address or alias of the target mailbox (Grant set).
    .PARAMETER User
        UPN of the user to grant permissions to (Grant set).
    .PARAMETER RecipientTypeDetails
        Mailbox types scanned in Mirror mode. Defaults to the four common types.
    .EXAMPLE
        Set-ExchangeMailboxPermission -SourceUser old@contoso.com -TargetUser new@contoso.com
        Mirrors all mailbox permissions from old@ to new@.
    .EXAMPLE
        Set-ExchangeMailboxPermission -Mailbox shared@contoso.com -User user@contoso.com
        Grants FullAccess, SendAs and SendOnBehalf on shared@ to user@.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Mirror', SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Mirror')]
        [ValidateNotNullOrEmpty()]
        [string]$SourceUser,

        [Parameter(Mandatory = $true, ParameterSetName = 'Mirror')]
        [ValidateNotNullOrEmpty()]
        [string]$TargetUser,

        [Parameter(Mandatory = $true, ParameterSetName = 'Grant')]
        [ValidateNotNullOrEmpty()]
        [string]$Mailbox,

        [Parameter(Mandatory = $true, ParameterSetName = 'Grant')]
        [ValidateNotNullOrEmpty()]
        [string]$User,

        [string[]]$RecipientTypeDetails = @('UserMailbox', 'SharedMailbox', 'RoomMailbox', 'EquipmentMailbox')
    )

    $action = $PSCmdlet.ParameterSetName
    $target = if ($action -eq 'Mirror') { "$SourceUser -> $TargetUser" } else { $Mailbox }

    if (-not $PSCmdlet.ShouldProcess($target, "Set mailbox permission ($action)")) {
        return "[!] Skipped by -WhatIf or -Confirm."
    }

    try {
        if ($action -eq 'Mirror') {
            $mailboxes = Get-Mailbox -RecipientTypeDetails $RecipientTypeDetails -ResultSize Unlimited -ErrorAction Stop
            $count = 0

            foreach ($mb in $mailboxes) {
                $fa = Get-MailboxPermission -Identity $mb.Alias -ErrorAction SilentlyContinue |
                          Where-Object { $_.User -like $SourceUser -and $_.AccessRights -contains 'FullAccess' }
                if ($fa) {
                    Add-MailboxPermission -Identity $mb.Alias -User $TargetUser `
                        -AccessRights FullAccess -InheritanceType All -AutoMapping:$false `
                        -ErrorAction SilentlyContinue | Out-Null
                    $count++
                }

                $sa = Get-RecipientPermission -Identity $mb.Alias -ErrorAction SilentlyContinue |
                          Where-Object { $_.Trustee -like $SourceUser -and $_.AccessRights -contains 'SendAs' }
                if ($sa) {
                    Add-RecipientPermission -Identity $mb.Alias -Trustee $TargetUser `
                        -AccessRights SendAs -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
                    $count++
                }

                $sobProp = $mb.PSObject.Properties['GrantSendOnBehalfTo']
                if ($sobProp -and $sobProp.Value) {
                    $local = ($SourceUser -split '@')[0]
                    $hasSob = @($sobProp.Value | Where-Object {
                        "$_" -like "*$SourceUser*" -or ($local -and "$_" -like "*$local*")
                    }).Count -gt 0
                    if ($hasSob) {
                        Set-Mailbox -Identity $mb.Alias `
                            -GrantSendOnBehalfTo @{ Add = $TargetUser } `
                            -ErrorAction SilentlyContinue | Out-Null
                        $count++
                    }
                }
            }

            $srcMasked = Hide-UpnLocalPart $SourceUser
            $tgtMasked = Hide-UpnLocalPart $TargetUser
            if ($count -gt 0) {
                return "[OK] Mirrored $count permission(s) from $srcMasked to $tgtMasked"
            }
            return "[!] No mailbox permissions found for $srcMasked"
        }
        else {
            Add-MailboxPermission -Identity $Mailbox -User $User `
                -AccessRights FullAccess -InheritanceType All -AutoMapping:$false `
                -ErrorAction Stop | Out-Null
            Add-RecipientPermission -Identity $Mailbox -Trustee $User `
                -AccessRights SendAs -Confirm:$false -ErrorAction Stop | Out-Null
            Set-Mailbox -Identity $Mailbox `
                -GrantSendOnBehalfTo @{ Add = $User } -ErrorAction Stop | Out-Null

            return "[OK] Granted FullAccess, SendAs and SendOnBehalf on $(Hide-UpnLocalPart $Mailbox) to $(Hide-UpnLocalPart $User)"
        }
    }
    catch {
        Write-Warning "Exchange permission operation failed (type: $($_.Exception.GetType().Name))."
        Write-Verbose "Exchange exception detail: $($_.Exception.Message)"
        return "[!] Operation failed. Verify Exchange Online connection and target mailbox/user."
    }
}
