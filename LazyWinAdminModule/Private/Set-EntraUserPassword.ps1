function Set-EntraUserPassword {
    <#
    .SYNOPSIS
        Resets an Entra ID user's password via Microsoft Graph and returns the new password once.
    .DESCRIPTION
        Generates a strong password, applies it with Update-MgUser and (by default)
        forces a change at next sign-in. Requires an active Graph session with the
        User.ReadWrite.All scope. The generated password is returned in-memory on the
        result object for ONE-TIME display / clipboard use only; it is never written
        to logs, error messages, or exports (classified: credential).
    .PARAMETER UserPrincipalName
        The user whose password is reset.
    .PARAMETER ForceChangeNextSignIn
        Require the user to change the password at next sign-in. Default $true.
    .OUTPUTS
        PSCustomObject with Status (string) and Password (string, or $null on failure).
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserPrincipalName,

        [bool]$ForceChangeNextSignIn = $true
    )

    if ($null -eq (Get-MgContext)) {
        return [PSCustomObject]@{ Status = '[!] Not connected to Microsoft Graph. Connect on the Cloud tab first.'; Password = $null }
    }
    if (-not $PSCmdlet.ShouldProcess($UserPrincipalName, 'Reset password')) {
        return [PSCustomObject]@{ Status = '[!] Skipped by -WhatIf or -Confirm.'; Password = $null }
    }

    try {
        $newPassword    = New-LwaSecurePassword -Length 16
        $passwordProfile = @{
            Password                      = $newPassword
            ForceChangePasswordNextSignIn = $ForceChangeNextSignIn
        }
        Update-MgUser -UserId $UserPrincipalName -PasswordProfile $passwordProfile -ErrorAction Stop | Out-Null
        return [PSCustomObject]@{ Status = "[OK] Password reset for $UserPrincipalName"; Password = $newPassword }
    }
    catch {
        Write-Verbose "Password reset exception: $_"
        return [PSCustomObject]@{ Status = '[!] Password reset failed. Verify the UPN and that you hold the required Graph scope.'; Password = $null }
    }
}
