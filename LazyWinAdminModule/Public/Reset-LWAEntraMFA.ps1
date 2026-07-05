function Reset-LWAEntraMFA {
    <#
    .SYNOPSIS
        Resets MFA for an Entra ID user (Forces re-registration) with automatic PIM elevation.
    .DESCRIPTION
        Calls Microsoft Graph to remove Microsoft Authenticator methods, elevating to Authentication Administrator if needed.
    .EXAMPLE
        Reset-LWAEntraMFA -UserPrincipalName 'user@domain.com' -Justification 'INC1234 User lost phone'
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

        # Fetch Microsoft Authenticator methods
        $methodsUri = "v1.0/users/$UserPrincipalName/authentication/microsoftAuthenticatorMethods"
        $methods = Invoke-MgGraphRequest -Method GET -Uri $methodsUri -ErrorAction Stop

        $deletedCount = 0
        foreach ($method in $methods.value) {
            $deleteUri = "v1.0/users/$UserPrincipalName/authentication/microsoftAuthenticatorMethods/$($method.id)"
            Invoke-MgGraphRequest -Method DELETE -Uri $deleteUri -ErrorAction Stop
            $deletedCount++
        }

        return [PSCustomObject]@{
            UserPrincipalName = $UserPrincipalName
            Success = $true
            MethodsRemoved = $deletedCount
            Action = 'ResetMFA'
        }
    }
    catch {
        Write-Verbose "Error resetting MFA for $($UserPrincipalName): $_"
        throw $_
    }
}
