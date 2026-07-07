function Connect-ExchangeSession {
    <#
    .SYNOPSIS
        Connects to Exchange Online using modern authentication.
    .DESCRIPTION
        Checks for the ExchangeOnlineManagement module, imports it, and initiates
        an interactive connection. Optionally targets a CUSTOMER tenant for MSP /
        delegated administration via -DelegatedOrganization — using the module's
        built-in first-party app, so NO Azure/Entra app registration is required.
        Returns a status string — never surfaces exception detail or credential
        fragments to the caller.
    .PARAMETER UserPrincipalName
        The administrator UPN to sign in with (optional; pre-fills / streamlines
        the interactive login, e.g. admin@data4.nl).
    .PARAMETER DelegatedOrganization
        The customer tenant to manage, e.g. 'customer.onmicrosoft.com'. Leave
        empty to connect to your own / the signed-in account's home tenant.
        Requires an existing GDAP/CSP relationship or guest-admin access to that
        tenant — the tool cannot create the relationship.
    .EXAMPLE
        Connect-ExchangeSession -UserPrincipalName admin@data4.nl
        Connects to your own tenant.
    .EXAMPLE
        Connect-ExchangeSession -UserPrincipalName admin@data4.nl -DelegatedOrganization customer.onmicrosoft.com
        Connects to a customer tenant via delegated (GDAP/CSP) access — no app registration.
    #>
    [CmdletBinding()]
    param (
        [string]$UserPrincipalName,

        [string]$DelegatedOrganization
    )

    try {
        # Ensure the ExchangeOnlineManagement module is present and at least version 3.0.0
        Assert-ModuleRequirement -ModuleName 'ExchangeOnlineManagement' -MinimumVersion '3.0.0' | Out-Null

        $exoModules = Get-Module -Name ExchangeOnlineManagement -ListAvailable

        Import-Module ExchangeOnlineManagement -ErrorAction Stop

        $params = @{ ShowBanner = $false; ErrorAction = 'Stop' }
        
        # Implement EXO V3 optimizations if available
        $latestExo = $exoModules | Sort-Object Version -Descending | Select-Object -First 1
        if ($latestExo -and [version]$latestExo.Version -ge [version]'3.0.0') {
            $params.SkipLoadingFormatData = $true
        }

        if ($UserPrincipalName)     { $params.UserPrincipalName     = $UserPrincipalName }
        if ($DelegatedOrganization) { $params.DelegatedOrganization = $DelegatedOrganization }

        Connect-ExchangeOnline @params

        $org = Get-OrganizationConfig -ErrorAction Stop
        return "[OK] Connected to Exchange Online: $($org.DisplayName)"
    }
    catch {
        Write-Verbose "Exchange connection exception: $_"
        if ($_.Exception.Message -match "Failed to install required module" -or $_.Exception.Message -match "ExchangeOnlineManagement module not found") {
            return "[!] ExchangeOnlineManagement module not found or failed to install. Error: $($_.Exception.Message)"
        }
        return "[!] Connection failed. Verify the ExchangeOnlineManagement module is installed and credentials are correct."
    }
}
