function Set-EntraUserAccountState {
    <#
    .SYNOPSIS
        Enables or blocks (disables) sign-in for an Entra ID user.
    .DESCRIPTION
        Wraps Update-MgUser -AccountEnabled. Blocking sign-in is the first step of
        offboarding. Requires an active Graph session with User.ReadWrite.All.
    .PARAMETER UserPrincipalName
        The user to change.
    .PARAMETER Enabled
        $true enables sign-in; $false blocks it.
    .OUTPUTS
        Status string.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserPrincipalName,

        [Parameter(Mandatory = $true)]
        [bool]$Enabled
    )

    if ($null -eq (Get-MgContext)) {
        return '[!] Not connected to Microsoft Graph. Connect on the Cloud tab first.'
    }

    $verb = if ($Enabled) { 'Enable sign-in' } else { 'Block sign-in' }
    if (-not $PSCmdlet.ShouldProcess($UserPrincipalName, $verb)) {
        return '[!] Skipped by -WhatIf or -Confirm.'
    }

    try {
        Update-MgUser -UserId $UserPrincipalName -AccountEnabled:$Enabled -ErrorAction Stop | Out-Null
        $stateWord = if ($Enabled) { 'enabled' } else { 'blocked' }
        return "[OK] Sign-in $stateWord for $UserPrincipalName"
    }
    catch {
        Write-Verbose "Account state exception: $_"
        return '[!] Account state update failed. Verify the UPN and your Graph permissions.'
    }
}
