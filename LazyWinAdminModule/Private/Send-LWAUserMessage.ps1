function Send-LWAUserMessage {
    <#
    .SYNOPSIS
        Sends a pop-up broadcast message to logged-in users on a remote computer.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    process {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            msg.exe * "$using:Message"
        } -ErrorAction Stop
        return "[OK] Broadcast message sent to users on $ComputerName."
    }
}
