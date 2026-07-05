function Get-LWAEntraLog {
    <#
    .SYNOPSIS
        Retrieves Entra ID audit or sign-in logs with automatic PIM elevation.
    .DESCRIPTION
        Queries Microsoft Graph for Entra ID logs (SignIns or DirectoryAudits).
        Elevates to Reports Reader via PIM if the active session lacks sufficient roles.
    .EXAMPLE
        Get-LWAEntraLog -LogType SignIns -UserPrincipalName 'user@domain.com' -Top 10 -Justification 'INC1234 Investigate login failure'
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('SignIns', 'DirectoryAudits')]
        [string]$LogType,

        [Parameter(Mandatory=$false)]
        [string]$UserPrincipalName,

        [Parameter(Mandatory=$false)]
        [int]$Top = 50,

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

        # Check for Reports Reader (02d610a1-9cb4-4828-9712-7d1a1005a30d) or Global Reader/Admin
        $reportsReader = '02d610a1-9cb4-4828-9712-7d1a1005a30d'
        $globalReader = 'f2ef992c-3afb-46b9-b7cf-a126ee74c451'
        
        $hasAccess = (Test-LWAEntraRole -RoleTemplateId $reportsReader) -or (Test-LWAEntraRole -RoleTemplateId $globalReader)

        if (-not $hasAccess) {
            if ([string]::IsNullOrWhiteSpace($Justification)) {
                throw "Active permission missing. Please provide a -Justification to elevate via PIM."
            }

            Write-Verbose "Attempting PIM Elevation for Reports Reader..."
            $elevate = Invoke-LWAEntraPIMElevation -RoleTemplateId $reportsReader -Justification $Justification
            if (-not $elevate.Success) {
                throw "PIM Elevation failed: $($elevate.Error)"
            }
        }

        $uri = ""
        if ($LogType -eq 'SignIns') {
            $uri = "v1.0/auditLogs/signIns?`$top=$Top"
            if ($UserPrincipalName) {
                $uri += "&`$filter=userPrincipalName eq '$UserPrincipalName'"
            }
        } else {
            $uri = "v1.0/auditLogs/directoryAudits?`$top=$Top"
            if ($UserPrincipalName) {
                # Audits target filtering by UPN is complex as it's within targetResources,
                # but we can do a broad filter or let Graph handle it if supported.
                $uri += "&`$filter=targetResources/any(t:t/userPrincipalName eq '$UserPrincipalName')"
            }
        }

        $response = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop

        return $response.value
    }
    catch {
        Write-Verbose "Error retrieving Entra Logs: $_"
        throw $_
    }
}
