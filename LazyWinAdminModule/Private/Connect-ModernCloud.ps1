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
            Connect-MgGraph -Scopes "User.ReadBasic.All", "Group.Read.All", "DeviceManagementManagedDevices.Read.All", "DeviceManagementConfiguration.Read.All"
        }
        elseif ($ClientId -and $ClientSecret) {
            Write-Verbose "Connecting via Service Principal..."
            $credential = [System.Management.Automation.PSCredential]::new($ClientId, $ClientSecret)
            $body = @{
                TenantId              = $TenantId
                ClientId              = $ClientId
                ClientSecretCredential = $credential
            }
            Connect-MgGraph @body
        }

        $context = Get-MgContext
        if ($context) {
            # TenantId is internal; account is non-sensitive display info
            return "[OK] Connected to Tenant: $($context.TenantId) as $($context.Account)"
        }
        return "[!] Authentication completed but Graph context could not be retrieved."
    }
    catch {
        # Write full exception to Verbose only — never surface token fragments or credentials in the return value
        Write-Verbose "Cloud connection exception detail: $_"
        return "[!] Connection failed. Verify credentials and network connectivity."
    }
}
