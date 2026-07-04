function Revoke-EntraUserSession {
    <#
    .SYNOPSIS
        Revokes all active sign-in sessions (refresh tokens) for an Entra ID user.
    .DESCRIPTION
        Calls Revoke-MgUserSignInSession, invalidating the user's refresh tokens so
        every session must re-authenticate. Used during offboarding or after a
        suspected account compromise. Requires an active Graph session.
    .PARAMETER UserPrincipalName
        The user whose sessions are revoked.
    .OUTPUTS
        Status string.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserPrincipalName
    )

    if ($null -eq (Get-MgContext)) {
        return '[!] Not connected to Microsoft Graph. Connect on the Cloud tab first.'
    }
    if (-not $PSCmdlet.ShouldProcess($UserPrincipalName, 'Revoke sign-in sessions')) {
        return '[!] Skipped by -WhatIf or -Confirm.'
    }

    try {
        Revoke-MgUserSignInSession -UserId $UserPrincipalName -ErrorAction Stop | Out-Null
        return "[OK] Revoked all sign-in sessions for $UserPrincipalName"
    }
    catch {
        Write-Verbose "Revoke session exception: $_"
        return '[!] Failed to revoke sessions. Verify the UPN and your Graph permissions.'
    }
}
