function Get-LWAMailboxStatistics {
    <#
    .SYNOPSIS
        Retrieves mailbox statistics (size, item count) from Exchange Online.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Identity
    )
    process {
        Assert-ModuleRequirement -ModuleName 'ExchangeOnlineManagement' -MinimumVersion '3.0.0' | Out-Null
        $stats = Get-MailboxStatistics -Identity $Identity -ErrorAction Stop
        return $stats | Select-Object DisplayName, ItemCount, TotalItemSize, LastLogonTime
    }
}
