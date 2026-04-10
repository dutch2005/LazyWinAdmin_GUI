function Connect-ModernCloud {
    <#
    .SYNOPSIS
        Connects to Microsoft Graph / Entra ID using modern authentication.
    .DESCRIPTION
        Supports two authentication modes:

        Interactive (-Interactive switch): Opens a browser-based interactive sign-in
        and requests the scopes required by LazyWinAdmin (User.ReadBasic.All,
        Group.Read.All, DeviceManagementManagedDevices.Read.All,
        DeviceManagementConfiguration.Read.All).

        Service Principal (-ClientId / -ClientSecret / -TenantId): Authenticates
        non-interactively using an Entra app registration credential.
        TenantId must be a GUID or an onmicrosoft.com domain name.

        The two modes are mutually exclusive. Using both in the same call is an error.
        Returns a status string prefixed with [OK] on success or [!] on failure.
        Exception detail and credential fragments are never included in the return value
        — they are written to the Verbose stream only.
    .PARAMETER TenantId
        Entra tenant identifier. Required for service principal mode.
        Must be a GUID (e.g. '00000000-0000-0000-0000-000000000000') or an
        onmicrosoft.com domain name (e.g. 'contoso.onmicrosoft.com').
        Not used in interactive mode.
    .PARAMETER ClientId
        Application (client) ID of the Entra app registration.
        Required for service principal mode, mutually exclusive with -Interactive.
    .PARAMETER ClientSecret
        Client secret for the app registration, provided as a SecureString.
        Required for service principal mode, mutually exclusive with -Interactive.
    .PARAMETER Interactive
        When specified, triggers a browser-based interactive sign-in.
        Mutually exclusive with -ClientId / -ClientSecret.
    .OUTPUTS
        System.String — starts with '[OK]' on success or '[!]' on failure/validation error.
    .EXAMPLE
        # Interactive sign-in
        Connect-ModernCloud -Interactive
    .EXAMPLE
        # Service principal sign-in
        $secret = Read-Host -AsSecureString 'Client Secret'
        Connect-ModernCloud -TenantId 'contoso.onmicrosoft.com' `
                            -ClientId '00000000-0000-0000-0000-000000000000' `
                            -ClientSecret $secret
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
        if ($Interactive -and ($ClientId -or $ClientSecret)) {
            return "[!] Specify either -Interactive or -ClientId/-ClientSecret, not both."
        }
        if (-not $Interactive -and (-not $ClientId -or -not $ClientSecret -or -not $TenantId)) {
            return "[!] Service principal mode requires -TenantId, -ClientId, and -ClientSecret."
        }
        if (-not $Interactive -and $TenantId -notmatch '^[a-fA-F0-9\-]{36}$|^[\w\-]+\.onmicrosoft\.com$') {
            return "[!] TenantId must be a GUID or an onmicrosoft.com domain name."
        }

        if ($Interactive) {
            Write-Verbose "Triggering interactive login..."
            Connect-MgGraph -Scopes "User.ReadBasic.All", "Group.Read.All", "DeviceManagementManagedDevices.Read.All", "DeviceManagementConfiguration.Read.All"
        }
        elseif ($ClientId -and $ClientSecret) {
            Write-Verbose "Connecting via Service Principal..."
            $credential = [System.Management.Automation.PSCredential]::new($ClientId, $ClientSecret)
            $body = @{
                TenantId               = $TenantId
                ClientId               = $ClientId
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
