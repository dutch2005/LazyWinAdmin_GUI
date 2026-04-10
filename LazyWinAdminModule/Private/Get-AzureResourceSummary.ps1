function Get-AzureResourceSummary {
    <#
    .SYNOPSIS
        Retrieves a summary of Azure resources grouped by type using Azure Resource Graph.
    .DESCRIPTION
        Uses Search-AzGraph (Az.ResourceGraph) for server-side aggregation.
        Avoids Get-AzResource which enumerates all resources client-side and does not scale.
        Requires Az.ResourceGraph module (included in Az).
    .OUTPUTS
        System.Object[] — array of PSCustomObject with properties:
          Name  (System.String)  — Azure resource type, e.g. 'microsoft.compute/virtualmachines'.
          Count (System.Int64)   — number of resources of that type in the subscription.
        Returns $null when not connected to Azure or when an error occurs.
    #>
    [CmdletBinding()]
    param ()

    process {
        try {
            $azContext = Get-AzContext
            if (-not $azContext) {
                Write-Warning "Not connected to Azure. Please run Connect-AzAccount."
                return $null
            }

            $query = "Resources | summarize Count=count() by ResourceType=type | order by Count desc"
            $results = Search-AzGraph -Query $query -ErrorAction Stop

            return $results | Select-Object @{ N = 'Name'; E = { $_.ResourceType } }, Count
        }
        catch {
            Write-Warning "Error querying Azure Resource Graph: $_"
            return $null
        }
    }
}
