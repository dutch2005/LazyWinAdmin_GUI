function Get-EntraLicenseSku {
    <#
    .SYNOPSIS
        Lists the tenant's Microsoft 365 license SKUs with consumed / available counts.
    .DESCRIPTION
        Wraps Get-MgSubscribedSku and computes Available = Enabled - Consumed for each
        SKU, so an operator can see at a glance which licenses are free to assign.
        Requires an active Graph session.
    .OUTPUTS
        PSCustomObject list (SkuPartNumber, SkuId, Enabled, Consumed, Available) or $null.
    #>
    [CmdletBinding()]
    param ()

    if ($null -eq (Get-MgContext)) {
        Write-Warning 'Not connected to Microsoft Graph.'
        return $null
    }

    try {
        return Get-MgSubscribedSku -ErrorAction Stop | ForEach-Object {
            $prepaid  = $_.PSObject.Properties['PrepaidUnits']
            $enabled  = if ($prepaid -and $prepaid.Value) { $prepaid.Value.Enabled } else { 0 }
            $consumed = $_.ConsumedUnits
            [PSCustomObject]@{
                SkuPartNumber = $_.SkuPartNumber
                SkuId         = $_.SkuId
                Enabled       = $enabled
                Consumed      = $consumed
                Available     = $enabled - $consumed
            }
        }
    }
    catch {
        Write-Warning "Error querying subscribed SKUs: $_"
        return $null
    }
}
