function Set-ExchangeMailboxPermission {
    <#
    .SYNOPSIS
        Mirrors or grants mailbox permissions in Exchange Online.
    .DESCRIPTION
        Two modes, selected by parameter set:
          Mirror — copies every FullAccess and SendAs permission held by SourceUser
                   across all shared mailboxes to TargetUser.  Used for offboarding /
                   role handover scenarios.  Use the -SourceUser + -TargetUser pair.
          Grant  — grants FullAccess and SendAs on a single named mailbox to a user.
                   Use the -Mailbox + -User pair.

        Parameter sets enforce the correct argument combination at bind time —
        callers cannot mix Mirror and Grant parameters in one call.
    .PARAMETER SourceUser
        UPN of the user whose permissions are copied (Mirror set).
    .PARAMETER TargetUser
        UPN of the user who receives the copied permissions (Mirror set).
    .PARAMETER Mailbox
        Primary SMTP address or alias of the target shared mailbox (Grant set).
    .PARAMETER User
        UPN of the user to grant permissions to (Grant set).
    .EXAMPLE
        Set-ExchangeMailboxPermission -SourceUser old@contoso.com -TargetUser new@contoso.com
        Mirrors all shared-mailbox permissions from old@ to new@.
    .EXAMPLE
        Set-ExchangeMailboxPermission -Mailbox shared@contoso.com -User user@contoso.com
        Grants FullAccess and SendAs on shared@ to user@.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Mirror', SupportsShouldProcess = $true)]
    param (
        # Mirror parameter set
        [Parameter(Mandatory = $true, ParameterSetName = 'Mirror')]
        [ValidateNotNullOrEmpty()]
        [string]$SourceUser,

        [Parameter(Mandatory = $true, ParameterSetName = 'Mirror')]
        [ValidateNotNullOrEmpty()]
        [string]$TargetUser,

        # Grant parameter set
        [Parameter(Mandatory = $true, ParameterSetName = 'Grant')]
        [ValidateNotNullOrEmpty()]
        [string]$Mailbox,

        [Parameter(Mandatory = $true, ParameterSetName = 'Grant')]
        [ValidateNotNullOrEmpty()]
        [string]$User
    )

    # The parameter binder has already enforced the correct combination —
    # missing or mixed params produce a ParameterBindingException before
    # this body runs.  No manual validation needed.
    $action = $PSCmdlet.ParameterSetName
    $target = if ($action -eq 'Mirror') { "$SourceUser -> $TargetUser" } else { $Mailbox }

    if (-not $PSCmdlet.ShouldProcess($target, "Set mailbox permission ($action)")) {
        return "[!] Skipped by -WhatIf or -Confirm."
    }

    try {
        if ($action -eq 'Mirror') {
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

            if ($count -gt 0) {
                return "[OK] Mirrored $count permission(s) from $SourceUser to $TargetUser"
            } else {
                return "[!] No shared mailbox permissions found for $SourceUser"
            }
        }
        else {
            # Grant parameter set
            Add-MailboxPermission -Identity $Mailbox -User $User `
                -AccessRights FullAccess -InheritanceType All -AutoMapping:$false `
                -ErrorAction Stop | Out-Null
            Add-RecipientPermission -Identity $Mailbox -Trustee $User `
                -AccessRights SendAs -Confirm:$false -ErrorAction Stop | Out-Null

            return "[OK] Granted FullAccess and SendAs on $Mailbox to $User"
        }
    }
    catch {
        Write-Warning "Exchange permission operation failed (type: $($_.Exception.GetType().Name))."
        Write-Verbose "Exchange exception detail: $($_.Exception.Message)"
        return "[!] Operation failed. Verify Exchange Online connection and target mailbox/user."
    }
}
