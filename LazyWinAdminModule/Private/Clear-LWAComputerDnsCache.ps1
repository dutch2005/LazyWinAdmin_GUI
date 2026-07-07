function Clear-LWAComputerDnsCache {
    <#
    .SYNOPSIS
        Clears the DNS resolver cache on a remote computer.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )
    process {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            Clear-DnsClientCache
        } -ErrorAction Stop
        return "[OK] DNS Client Cache flushed on $ComputerName."
    }
}
