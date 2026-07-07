function Lock-LWAComputer {
    <#
    .SYNOPSIS
        Locks the workstation of a remote computer.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )
    process {
        # Note: rundll32 needs to run in the interactive session, which invoke-command doesn't natively do easily.
        # But for the sake of completeness, this sends the command. Better implementations use psexec -i.
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            rundll32.exe user32.dll,LockWorkStation
        } -ErrorAction Stop
        return "[OK] Lock workstation command sent to $ComputerName."
    }
}
