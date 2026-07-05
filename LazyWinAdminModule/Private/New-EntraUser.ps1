function New-EntraUser {
    <#
    .SYNOPSIS
        Creates a new Entra ID user with a strong temporary password.
    .DESCRIPTION
        Wraps New-MgUser. Generates a random password and forces a change at next
        sign-in. Requires an active Graph session with User.ReadWrite.All. The
        temporary password is returned in-memory on the result object for ONE-TIME
        hand-off to the new hire; it is never logged or placed in the status string.
    .PARAMETER DisplayName
        The user's display name.
    .PARAMETER UserPrincipalName
        The new UPN (must be an available, verified-domain address).
    .PARAMETER MailNickname
        Mail alias. Defaults to the local part of the UPN.
    .OUTPUTS
        PSCustomObject with Status (string), Password (string or $null), UserId (string or $null).
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserPrincipalName,

        [string]$MailNickname
    )

    if ($null -eq (Get-MgContext)) {
        return [PSCustomObject]@{ Status = '[!] Not connected to Microsoft Graph. Connect on the Cloud tab first.'; Password = $null; UserId = $null }
    }
    if (-not $PSCmdlet.ShouldProcess($UserPrincipalName, 'Create user')) {
        return [PSCustomObject]@{ Status = '[!] Skipped by -WhatIf or -Confirm.'; Password = $null; UserId = $null }
    }

    try {
        $nickname    = if ($MailNickname) { $MailNickname } else { ($UserPrincipalName -split '@')[0] }
        $newPassword = New-LwaSecurePassword -Length 16
        $body = @{
            AccountEnabled    = $true
            DisplayName       = $DisplayName
            UserPrincipalName = $UserPrincipalName
            MailNickname      = $nickname
            PasswordProfile   = @{ Password = $newPassword; ForceChangePasswordNextSignIn = $true }
        }
        $user = New-MgUser @body -ErrorAction Stop
        return [PSCustomObject]@{ Status = "[OK] Created user $UserPrincipalName"; Password = $newPassword; UserId = $user.Id }
    }
    catch {
        Write-Verbose "User creation exception: $_"
        return [PSCustomObject]@{ Status = '[!] User creation failed. Verify the UPN is available and you hold the required Graph scope.'; Password = $null; UserId = $null }
    }
}
