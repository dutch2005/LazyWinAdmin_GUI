function Invoke-LWAComputerCommand {
    <#
    .SYNOPSIS
        Executes a script block on a remote computer using PowerShell Remoting.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock
    )
    process {
        return Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ErrorAction Stop
    }
}
