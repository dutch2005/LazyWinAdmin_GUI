function Invoke-EntraUserOffboarding {
    <#
    .SYNOPSIS
        Runs the standard leaver checklist for a user. Every step is opt-in.
    .DESCRIPTION
        Composes the individually-tested atomic operations into one workflow. Steps run
        in a safe order (block sign-in first, licenses last). A failure in one step is
        recorded and does NOT abort the rest. Returns a list of per-step results so the
        UI can show exactly what happened. Passing -WhatIf performs a dry run: it
        propagates to every underlying step, which each report a skip without changing
        anything. The reset-password step deliberately omits the new password from the
        report (the account is being disabled; the value is not needed and is a secret).
    .PARAMETER UserPrincipalName
        The leaver.
    .PARAMETER BlockSignIn
        Disable the account so the user cannot sign in.
    .PARAMETER RevokeSessions
        Invalidate all refresh tokens.
    .PARAMETER ResetPassword
        Reset the password to a random value (locks out cached credentials).
    .PARAMETER ConvertMailboxToShared
        Convert the mailbox to Shared so mail is retained without a license.
    .PARAMETER AutoReplyMessage
        When supplied, enable an Out-of-Office auto-reply with this text.
    .PARAMETER DelegateMailboxTo
        UPN of a manager/successor to grant FullAccess/SendAs/SendOnBehalf on the mailbox.
    .PARAMETER RemoveLicenseSkuId
        One or more SKU ids to remove (do this AFTER converting to shared).
    .PARAMETER RemoveFromGroups
        Remove the user from every group they belong to.
    .OUTPUTS
        List of PSCustomObject (Step, Result).
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.Collections.Generic.List[object]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserPrincipalName,

        [switch]$BlockSignIn,
        [switch]$RevokeSessions,
        [switch]$ResetPassword,
        [switch]$ConvertMailboxToShared,
        [string]$AutoReplyMessage,
        [string]$DelegateMailboxTo,
        [string[]]$RemoveLicenseSkuId,
        [switch]$RemoveFromGroups
    )

    if (-not $PSCmdlet.ShouldProcess($UserPrincipalName, 'Run offboarding workflow')) {
        $dry = [System.Collections.Generic.List[object]]::new()
        $dry.Add([PSCustomObject]@{ Step = 'Dry run'; Result = "[!] -WhatIf: would run the selected offboarding steps for $UserPrincipalName." })
        return $dry
    }

    $report = [System.Collections.Generic.List[object]]::new()
    $record = {
        param([string]$step, [string]$result)
        $report.Add([PSCustomObject]@{ Step = $step; Result = $result })
    }

    if ($BlockSignIn) {
        & $record 'Block sign-in' (Set-EntraUserAccountState -UserPrincipalName $UserPrincipalName -Enabled:$false)
    }
    if ($RevokeSessions) {
        & $record 'Revoke sessions' (Revoke-EntraUserSession -UserPrincipalName $UserPrincipalName)
    }
    if ($ResetPassword) {
        $pwResult = Set-EntraUserPassword -UserPrincipalName $UserPrincipalName
        & $record 'Reset password' $pwResult.Status
    }
    if ($ConvertMailboxToShared) {
        & $record 'Convert mailbox to shared' (Convert-ExchangeMailbox -Mailbox $UserPrincipalName -Type Shared)
    }
    if ($PSBoundParameters.ContainsKey('AutoReplyMessage')) {
        & $record 'Set auto-reply' (Set-ExchangeAutoReply -Mailbox $UserPrincipalName -State Enabled `
            -InternalMessage $AutoReplyMessage -ExternalMessage $AutoReplyMessage)
    }
    if ($DelegateMailboxTo) {
        & $record 'Delegate mailbox' (Set-ExchangeMailboxPermission -Mailbox $UserPrincipalName -User $DelegateMailboxTo)
    }
    if ($RemoveLicenseSkuId) {
        foreach ($sku in $RemoveLicenseSkuId) {
            & $record "Remove license $sku" (Set-EntraUserLicense -UserPrincipalName $UserPrincipalName -RemoveSkuId $sku)
        }
    }
    if ($RemoveFromGroups) {
        $objectId = try { (Get-MgUser -UserId $UserPrincipalName -ErrorAction Stop).Id } catch { $null }
        if (-not $objectId) {
            & $record 'Remove from groups' '[!] Could not resolve the user object id; group removal skipped.'
        }
        else {
            $groups = @(Get-EntraUserMembership -UserPrincipalName $UserPrincipalName | Where-Object { $_ })
            if ($groups.Count -eq 0) {
                & $record 'Remove from groups' '[OK] No group memberships to remove.'
            }
            foreach ($g in $groups) {
                & $record "Remove from group $($g.DisplayName)" (Set-EntraGroupMembership -GroupId $g.Id -UserId $objectId -Action Remove)
            }
        }
    }

    if ($report.Count -eq 0) {
        & $record 'No action' '[!] No offboarding steps were selected.'
    }

    return $report
}
