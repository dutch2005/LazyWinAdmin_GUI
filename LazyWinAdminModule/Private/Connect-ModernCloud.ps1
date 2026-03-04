function Connect-ModernCloud {
    <#
    .SYNOPSIS
        Connects to Microsoft Graph / Entra ID using modern authentication.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$TenantId,

        [string]$ClientId,

        [string]$ClientSecret,

        [switch]$Interactive
    )

    try {
        if ($Interactive) {
            Write-Verbose "Triggering interactive login..."
            Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "DeviceManagementManagedDevices.Read.All"
        }
        elseif ($ClientId -and $ClientSecret) {
            Write-Verbose "Connecting via Service Principal..."
            $body = @{
                TenantId = $TenantId
                ClientId = $ClientId
                ClientSecret = $ClientSecret
            }
            Connect-MgGraph @body
        }
        
        $context = Get-MgContext
        if ($context) {
            return "[OK] Connected to Tenant: $($context.TenantId) as $($context.Account)"
        }
        return "[!] Failed to retrieve Graph context."
    }
    catch {
        Write-Warning "Cloud Connection Failed: $_"
        return "Error: $_"
    }
}