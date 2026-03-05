function Get-AzureResourceSummary {
    <#
    .SYNOPSIS
        Retrieves a summary of Azure resources and basic cost insights.
    #>
    [CmdletBinding()]
    param ()

    process {
        try {
            # Check for Az context
            $azContext = Get-AzContext
            if (-not $azContext) {
                Write-Warning "Not connected to Azure. Please run Connect-AzAccount."
                return $null
            }

            $resources = Get-AzResource
            $summary = $resources | Group-Object ResourceType | Select-Object Name, Count | Sort-Object Count -Descending
            
            return $summary
        }
        catch {
            Write-Warning "Error querying Azure resources: $_"
            return $null
        }
    }
}