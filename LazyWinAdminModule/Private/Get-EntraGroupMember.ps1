function Get-EntraGroupMember {
    <#
    .SYNOPSIS
        Lists the members of an Entra ID group.
    .DESCRIPTION
        Wraps Get-MgGroupMember. Requires an active Graph session. Property access is
        guarded for Set-StrictMode safety.
    .PARAMETER GroupId
        The group's directory object id.
    .OUTPUTS
        PSCustomObject list (DisplayName, UserPrincipalName, Id) or $null.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$GroupId
    )

    if ($null -eq (Get-MgContext)) {
        Write-Warning 'Not connected to Microsoft Graph.'
        return $null
    }

    try {
        return Get-MgGroupMember -GroupId $GroupId -All -ErrorAction Stop | ForEach-Object {
            $apProp = $_.PSObject.Properties['AdditionalProperties']
            $ap     = if ($apProp) { $apProp.Value } else { $null }
            [PSCustomObject]@{
                DisplayName       = if ($ap -and $ap.ContainsKey('displayName'))       { $ap['displayName'] }       else { $_.Id }
                UserPrincipalName = if ($ap -and $ap.ContainsKey('userPrincipalName')) { $ap['userPrincipalName'] } else { $null }
                Id                = $_.Id
            }
        }
    }
    catch {
        Write-Warning "Error querying group members: $_"
        return $null
    }
}
