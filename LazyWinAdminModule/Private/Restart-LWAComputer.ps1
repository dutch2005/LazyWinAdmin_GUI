function Restart-LWAComputer {
    <#
    .SYNOPSIS
        Restarts a local or remote computer.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,
        [switch]$Force
    )
    process {
        Restart-Computer -ComputerName $ComputerName -Force:$Force -ErrorAction Stop
        return "[OK] Restart command sent to $ComputerName."
    }
}
