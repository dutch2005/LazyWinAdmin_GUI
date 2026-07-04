function Get-EntraUserMembership {
    <#
    .SYNOPSIS
        Lists the groups and directory roles an Entra ID user is a member of.
    .DESCRIPTION
        Wraps Get-MgUserMemberOf. Requires an active Graph session. Property access on
        the returned directory objects is guarded so the function is safe under
        Set-StrictMode.
    .PARAMETER UserPrincipalName
        The user (UPN or object id) to query.
    .OUTPUTS
        PSCustomObject list (DisplayName, Id, Type) or $null.
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
        return Get-MgUserMemberOf -UserId $UserPrincipalName -All -ErrorAction Stop | ForEach-Object {
            $apProp = $_.PSObject.Properties['AdditionalProperties']
            $ap     = if ($apProp) { $apProp.Value } else { $null }
            $name   = if ($ap -and $ap.ContainsKey('displayName')) { $ap['displayName'] } else { $_.Id }
            $type   = if ($ap -and $ap.ContainsKey('@odata.type'))  { $ap['@odata.type'] -replace '#microsoft.graph.', '' } else { 'unknown' }
            [PSCustomObject]@{
                DisplayName = $name
                Id          = $_.Id
                Type        = $type
            }
        }
    }
    catch {
        Write-Warning "Error querying user membership: $_"
        return $null
    }
}
