function Add-LWAExchangeBlockListDomain {
    <#
    .SYNOPSIS
        Adds domains or sender email addresses to the Tenant Allow/Block List in Exchange Online.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$Entries,
        [Parameter(Mandatory=$false)]
        [string]$Note = "Added via LazyWinAdmin"
    )
    process {
        Assert-ModuleRequirement -ModuleName 'ExchangeOnlineManagement' -MinimumVersion '3.0.0' | Out-Null
        
        # In Defender for Office 365 / EXO V3, New-TenantAllowBlockListItems is used
        New-TenantAllowBlockListItems -ListType Sender -Block -Entries $Entries -Notes $Note -ErrorAction Stop
        
        return "[OK] Added $($Entries.Count) items to the Exchange Tenant Block List."
    }
}
