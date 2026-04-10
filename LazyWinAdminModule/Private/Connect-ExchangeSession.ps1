function Connect-ExchangeSession {
    <#
    .SYNOPSIS
        Connects to Exchange Online using modern authentication.
    .DESCRIPTION
        Checks for the ExchangeOnlineManagement module, imports it, and initiates
        an interactive connection. Returns a status string — never surfaces
        exception detail or credential fragments to the caller.
    .PARAMETER UserPrincipalName
        Optional UPN (e.g. 'admin@contoso.com') used to pre-fill the sign-in dialog.
        When omitted, the user is prompted to enter credentials interactively.
    .OUTPUTS
        System.String — starts with '[OK]' followed by the organisation display name
        on success, or '[!]' with an error description on failure.
    #>
    [CmdletBinding()]
    param (
        [string]$UserPrincipalName
    )

    try {
        if (-not (Get-Module -Name ExchangeOnlineManagement -ListAvailable)) {
            return "[!] ExchangeOnlineManagement module not found. Install with: Install-Module ExchangeOnlineManagement -Scope CurrentUser"
        }

        Import-Module ExchangeOnlineManagement -ErrorAction Stop

        $params = @{ ShowBanner = $false; ErrorAction = 'Stop' }
        if ($UserPrincipalName) { $params.UserPrincipalName = $UserPrincipalName }

        Connect-ExchangeOnline @params

        $org = Get-OrganizationConfig -ErrorAction Stop
        return "[OK] Connected to Exchange Online: $($org.DisplayName)"
    }
    catch {
        Write-Verbose "Exchange connection exception: $_"
        return "[!] Connection failed. Verify the ExchangeOnlineManagement module is installed and credentials are correct."
    }
}
