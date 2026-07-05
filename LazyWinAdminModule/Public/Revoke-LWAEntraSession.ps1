function Revoke-LWAEntraSession {
    <#
    .SYNOPSIS
        Revokes sign-in sessions for an Entra ID user with automatic PIM elevation.
    .DESCRIPTION
        Calls Microsoft Graph to revoke user sessions, elevating to Authentication Administrator if needed.
    .EXAMPLE
        Revoke-LWAEntraSession -UserPrincipalName 'user@domain.com' -Justification 'INC1234 Account compromised'
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$UserPrincipalName,

        [Parameter(Mandatory=$false)]
        [ValidateScript({
            if ($null -ne $_ -and $_.Trim().Length -lt 10) { throw "Justification must be at least 10 characters." }
            if ($null -ne $_ -and $_ -notmatch '(?i)^(INC|REQ|TKT|CHG|RITM|IT)\d+ .') {
                throw "Justification must start with a valid ticket format (e.g., INC1234, TKT5678) followed by a short motivation."
            }
            return $true
        })]
        [string]$Justification
    )

    try {
        $context = Get-MgContext -ErrorAction SilentlyContinue
        if (-not $context) { throw "Not connected to Microsoft Graph." }

        # Authentication Administrator
        $authAdmin = 'c4e39bd9-1100-46d3-8c65-fb160da0071f'
        $hasAccess = Test-LWAEntraRole -RoleTemplateId $authAdmin

        if (-not $hasAccess) {
            if ([string]::IsNullOrWhiteSpace($Justification)) {
                throw "Active permission missing. Please provide a -Justification to elevate via PIM."
            }

            Write-Verbose "Attempting PIM Elevation for Authentication Administrator..."
            $elevate = Invoke-LWAEntraPIMElevation -RoleTemplateId $authAdmin -Justification $Justification
            if (-not $elevate.Success) {
                throw "PIM Elevation failed: $($elevate.Error)"
            }
        }

        $uri = "v1.0/users/$UserPrincipalName/revokeSignInSessions"
        $response = Invoke-MgGraphRequest -Method POST -Uri $uri -ErrorAction Stop

        return [PSCustomObject]@{
            UserPrincipalName = $UserPrincipalName
            Success = $response.value
            Action = 'RevokeSignInSessions'
        }
    }
    catch {
        Write-Verbose "Error revoking sessions for $($UserPrincipalName): $_"
        throw $_
    }
}
