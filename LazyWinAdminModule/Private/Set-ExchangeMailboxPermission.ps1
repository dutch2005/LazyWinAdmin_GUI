function Set-ExchangeMailboxPermission {
    <#
    .SYNOPSIS
        Mirrors or grants mailbox permissions in Exchange Online.
    .DESCRIPTION
        Two modes:
          Mirror — copies every FullAccess and SendAs permission held by SourceUser
                   across all shared mailboxes to TargetUser.  Used for offboarding /
                   role handover scenarios.
          Grant  — grants FullAccess and SendAs on a single named mailbox to a user.
    .PARAMETER Action
        'Mirror' or 'Grant'.
    .PARAMETER SourceUser
        UPN of the user whose permissions are copied (Mirror only).
    .PARAMETER TargetUser
        UPN of the user who receives the copied permissions (Mirror only).
    .PARAMETER Mailbox
        Primary SMTP address or alias of the target shared mailbox (Grant only).
    .PARAMETER User
        UPN of the user to grant permissions to (Grant only).
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('Mirror', 'Grant')]
        [string]$Action,

        # Mirror parameters
        [string]$SourceUser,
        [string]$TargetUser,

        # Grant parameters
        [string]$Mailbox,
        [string]$User
    )

    if (-not $PSCmdlet.ShouldProcess($Mailbox, "Set mailbox permission")) {
        return "[!] Skipped by -WhatIf or -Confirm."
    }

    try {
        if ($Action -eq 'Mirror') {
            if (-not $SourceUser -or -not $TargetUser) {
                return "[!] Mirror requires both SourceUser and TargetUser."
            }

            $sharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox -ErrorAction Stop
            $count = 0

            foreach ($mb in $sharedMailboxes) {
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
            }

            return if ($count -gt 0) {
                "[OK] Mirrored $count permission(s) from $SourceUser to $TargetUser"
            } else {
                "[!] No shared mailbox permissions found for $SourceUser"
            }
        }
        elseif ($Action -eq 'Grant') {
            if (-not $Mailbox -or -not $User) {
                return "[!] Grant requires both Mailbox and User."
            }

            Add-MailboxPermission -Identity $Mailbox -User $User `
                -AccessRights FullAccess -InheritanceType All -AutoMapping:$false `
                -ErrorAction Stop | Out-Null
            Add-RecipientPermission -Identity $Mailbox -Trustee $User `
                -AccessRights SendAs -Confirm:$false -ErrorAction Stop | Out-Null

            return "[OK] Granted FullAccess and SendAs on $Mailbox to $User"
        }
    }
    catch {
        Write-Warning "Exchange permission operation failed: $_"
        return "[!] Operation failed. Verify Exchange Online connection and target mailbox/user."
    }
}
