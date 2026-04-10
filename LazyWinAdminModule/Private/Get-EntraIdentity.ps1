function Get-EntraIdentity {
    <#
    .SYNOPSIS
        Retrieves users or groups from Entra ID using Microsoft Graph.
    .DESCRIPTION
        Queries Microsoft Graph using OData $filter expressions against the
        displayName and (for users) userPrincipalName properties.
        Results are limited to a maximum of 50 objects per call (-Top 50).

        Input validation rejects characters not safe for OData $filter strings
        before the query is constructed. Single quotes in the search term are
        escaped as two consecutive single quotes so that the OData filter string
        remains syntactically valid and cannot be broken by user input.

        Requires an active Microsoft Graph session (Connect-ModernCloud or
        Connect-MgGraph) with at least User.ReadBasic.All and Group.Read.All scopes.
    .PARAMETER Type
        Object type to query. Valid values: User, Group.
    .PARAMETER Search
        Optional search string. Must contain only alphanumeric characters, spaces,
        hyphens, dots, @ signs, and underscores. Single quotes are automatically
        escaped. When provided, a startsWith OData filter is applied; when omitted,
        the first 50 objects of the requested type are returned (-Top 50 pagination
        limit applies in both cases).
    .OUTPUTS
        System.Object[] — array of selected properties, or $null on error or when
        not connected to Graph.

        User objects include: DisplayName, UserPrincipalName, Id, Mail, JobTitle.
        Group objects include: DisplayName, Id, Description, GroupTypes.
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
                    $SafeSearch = $Search.Trim() -replace "'", "''"
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
                    $SafeSearch = $Search.Trim() -replace "'", "''"
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
