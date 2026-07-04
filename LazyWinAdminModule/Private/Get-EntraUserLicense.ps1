function Get-EntraUserLicense {
    <#
    .SYNOPSIS
        Lists the Microsoft 365 licenses currently assigned to an Entra ID user.
    .DESCRIPTION
        Wraps Get-MgUserLicenseDetail. Requires an active Graph session.
    .PARAMETER UserPrincipalName
        The user to query.
    .OUTPUTS
        PSCustomObject list (SkuPartNumber, SkuId) or $null.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserPrincipalName
    )

    if ($null -eq (Get-MgContext)) {
        Write-Warning 'Not connected to Microsoft Graph.'
        return $null
    }

    try {
        return Get-MgUserLicenseDetail -UserId $UserPrincipalName -ErrorAction Stop |
            ForEach-Object {
                [PSCustomObject]@{
                    SkuPartNumber = $_.SkuPartNumber
                    SkuId         = $_.SkuId
                }
            }
    }
    catch {
        Write-Warning "Error querying user licenses: $_"
        return $null
    }
}
