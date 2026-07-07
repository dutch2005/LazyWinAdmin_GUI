function Start-LWARemoteDesktop {
    <#
    .SYNOPSIS
        Launches the Remote Desktop Connection client targeting the specified computer.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )
    process {
        Start-Process -FilePath "mstsc.exe" -ArgumentList "/v:$ComputerName" -ErrorAction Stop
        return "[OK] Remote Desktop launched for $ComputerName."
    }
}
