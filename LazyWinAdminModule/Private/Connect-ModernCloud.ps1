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

        [SecureString]$ClientSecret,

        [switch]$Interactive
    )

    try {
        if ($Interactive) {
            Write-Verbose "Triggering interactive login..."
            Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "DeviceManagementManagedDevices.Read.All"
        }
        elseif ($ClientId -and $ClientSecret) {
            Write-Verbose "Connecting via Service Principal..."
            # Convert SecureString to string securely for the underlying API if needed, 
            # or pass it if the module supports it. Connect-MgGraph natively supports -ClientSecretCredential.
            # We'll use the proper credential approach.
            $credential = [System.Management.Automation.PSCredential]::new($ClientId, $ClientSecret)
            $body = @{
                TenantId = $TenantId
                ClientId = $ClientId
                ClientSecretCredential = $credential
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