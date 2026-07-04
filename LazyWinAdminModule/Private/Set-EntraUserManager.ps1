function Set-EntraUserManager {
    <#
    .SYNOPSIS
        Sets the manager of an Entra ID user.
    .DESCRIPTION
        Wraps Set-MgUserManagerByRef. Requires an active Graph session with
        User.ReadWrite.All. Both ids are directory object ids.
    .PARAMETER UserId
        The user's directory object id.
    .PARAMETER ManagerId
        The manager's directory object id.
    .OUTPUTS
        Status string.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ManagerId
    )

    if ($null -eq (Get-MgContext)) {
        return '[!] Not connected to Microsoft Graph. Connect on the Cloud tab first.'
    }
    if (-not $PSCmdlet.ShouldProcess($UserId, 'Set manager')) {
        return '[!] Skipped by -WhatIf or -Confirm.'
    }

    try {
        Set-MgUserManagerByRef -UserId $UserId `
            -BodyParameter @{ '@odata.id' = "https://graph.microsoft.com/v1.0/users/$ManagerId" } `
            -ErrorAction Stop | Out-Null
        return "[OK] Set manager for $UserId"
    }
    catch {
        Write-Verbose "Set manager exception: $_"
        return '[!] Set manager failed. Verify the ids and your Graph permissions.'
    }
}
