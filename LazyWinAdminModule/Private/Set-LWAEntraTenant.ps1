function Set-LWAEntraTenant {
    <#
    .SYNOPSIS
        Switches the Entra ID / Microsoft Graph context to a specific Tenant (MSP / GDAP).
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$TenantId
    )
    process {
        Assert-ModuleRequirement -ModuleName 'Microsoft.Graph.Authentication' | Out-Null
        Connect-MgGraph -TenantId $TenantId -Scopes "User.ReadBasic.All", "Group.Read.All", "DeviceManagementManagedDevices.Read.All", "DeviceManagementConfiguration.Read.All" -ErrorAction Stop
        $context = Get-MgContext
        return "[OK] Switched context to Tenant: $($context.TenantId) as $($context.Account)"
    }
}
