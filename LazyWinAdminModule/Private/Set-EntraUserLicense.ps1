function Set-EntraUserLicense {
    <#
    .SYNOPSIS
        Assigns and/or removes a Microsoft 365 license SKU on an Entra ID user.
    .DESCRIPTION
        Wraps Set-MgUserLicense. Supply -AddSkuId, -RemoveSkuId, or both. Requires an
        active Graph session with User.ReadWrite.All. Removing the SKU that hosts a
        mailbox can orphan mailbox data, so confirm the mailbox is converted to shared
        first (see the offboarding workflow).
    .PARAMETER UserPrincipalName
        The user to change.
    .PARAMETER AddSkuId
        SkuId (GUID) to assign.
    .PARAMETER RemoveSkuId
        SkuId (GUID) to remove.
    .OUTPUTS
        Status string.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserPrincipalName,

        [string]$AddSkuId,

        [string]$RemoveSkuId
    )

    if ($null -eq (Get-MgContext)) {
        return '[!] Not connected to Microsoft Graph. Connect on the Cloud tab first.'
    }
    if (-not $AddSkuId -and -not $RemoveSkuId) {
        return '[!] Specify a SKU to add and/or remove.'
    }

    $target = "$UserPrincipalName (add: '$AddSkuId' remove: '$RemoveSkuId')"
    if (-not $PSCmdlet.ShouldProcess($target, 'Set user license')) {
        return '[!] Skipped by -WhatIf or -Confirm.'
    }

    try {
        $add    = @()
        $remove = @()
        if ($AddSkuId)    { $add    = @(@{ SkuId = $AddSkuId }) }
        if ($RemoveSkuId) { $remove = @($RemoveSkuId) }

        Set-MgUserLicense -UserId $UserPrincipalName -AddLicenses $add -RemoveLicenses $remove -ErrorAction Stop | Out-Null
        return "[OK] Updated licenses for $UserPrincipalName"
    }
    catch {
        Write-Verbose "License update exception: $_"
        return '[!] License update failed. Verify the UPN and SKU IDs.'
    }
}
