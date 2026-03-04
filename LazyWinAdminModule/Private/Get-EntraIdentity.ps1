function Get-EntraIdentity {
    <#
    .SYNOPSIS
        Retrieves users or groups from Entra ID using Microsoft Graph.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("User", "Group")]
        [string]$Type,

        [string]$Search
    )

    try {
        if ($null -eq (Get-MgContext)) {
            Write-Warning "Not connected to Microsoft Graph. Please login in the Cloud tab."
            return $null
        }

        if ($Type -eq "User") {
            if ($Search) {
                return Get-MgUser -Filter "startsWith(DisplayName, '$Search') or startsWith(UserPrincipalName, '$Search')" -Top 50 | 
                       Select-Object DisplayName, UserPrincipalName, Id, Mail, JobTitle
            }
            return Get-MgUser -Top 50 | Select-Object DisplayName, UserPrincipalName, Id, Mail, JobTitle
        }
        else {
            if ($Search) {
                return Get-MgGroup -Filter "startsWith(DisplayName, '$Search')" -Top 50 | 
                       Select-Object DisplayName, Id, Description, GroupTypes
            }
            return Get-MgGroup -Top 50 | Select-Object DisplayName, Id, Description, GroupTypes
        }
    }
    catch {
        Write-Warning "Error querying Entra ID: $_"
        return $null
    }
}