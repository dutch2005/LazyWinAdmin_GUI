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

    process {
        try {
            if ($null -eq (Get-MgContext)) {
                Write-Warning "Not connected to Microsoft Graph. Please login in the Cloud tab."
                return $null
            }

            # Validate EntraFilter: allow only characters safe for OData $filter strings
            if ($Search -and $Search -match "[^a-zA-Z0-9\s\-\.\@_]") {
                Write-Warning "Search term contains characters not permitted in an Entra filter."
                return $null
            }

            if ($Type -eq "User") {
                if ($Search) {
                    $SafeSearch = $Search.Trim()
                    return Get-MgUser `
                        -Filter "startsWith(displayName,'$SafeSearch') or startsWith(userPrincipalName,'$SafeSearch')" `
                        -Top 50 |
                        Select-Object DisplayName, UserPrincipalName, Id, Mail, JobTitle
                }
                return Get-MgUser -Top 50 |
                       Select-Object DisplayName, UserPrincipalName, Id, Mail, JobTitle
            }
            else {
                if ($Search) {
                    $SafeSearch = $Search.Trim()
                    return Get-MgGroup `
                        -Filter "startsWith(displayName,'$SafeSearch')" `
                        -Top 50 |
                        Select-Object DisplayName, Id, Description, GroupTypes
                }
                return Get-MgGroup -Top 50 |
                       Select-Object DisplayName, Id, Description, GroupTypes
            }
        }
        catch {
            Write-Warning "Error querying Entra ID: $_"
            return $null
        }
    }
}
