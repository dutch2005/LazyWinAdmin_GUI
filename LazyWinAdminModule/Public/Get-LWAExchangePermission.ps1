function Get-LWAExchangePermission {
    <#
    .SYNOPSIS
        Retrieves Exchange mailbox rules and settings via Graph API with PIM elevation.
    .DESCRIPTION
        Calls Microsoft Graph to retrieve mailbox rules, elevating to Exchange Administrator if needed.
    .EXAMPLE
        Get-LWAExchangePermission -UserPrincipalName 'user@domain.com' -Justification 'INC1234 Check rules'
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

        # Exchange Administrator
        $exchangeAdmin = '29232cdf-9323-42fd-ade2-1d097af3e4de'
        $hasAccess = Test-LWAEntraRole -RoleTemplateId $exchangeAdmin

        if (-not $hasAccess) {
            if ([string]::IsNullOrWhiteSpace($Justification)) {
                throw "Active permission missing. Please provide a -Justification to elevate via PIM."
            }

            Write-Verbose "Attempting PIM Elevation for Exchange Administrator..."
            $elevate = Invoke-LWAEntraPIMElevation -RoleTemplateId $exchangeAdmin -Justification $Justification
            if (-not $elevate.Success) {
                throw "PIM Elevation failed: $($elevate.Error)"
            }
        }

        # Fetch Inbox Rules
        $rulesUri = "v1.0/users/$UserPrincipalName/mailFolders/inbox/messageRules"
        $rules = Invoke-MgGraphRequest -Method GET -Uri $rulesUri -ErrorAction SilentlyContinue

        return [PSCustomObject]@{
            UserPrincipalName = $UserPrincipalName
            Success = $true
            InboxRules = $rules.value
            Action = 'GetExchangeSettings'
        }
    }
    catch {
        Write-Verbose "Error retrieving Exchange details for $($UserPrincipalName): $_"
        throw $_
    }
}
