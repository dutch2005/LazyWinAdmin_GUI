function Invoke-LWALogoff {
    <#
    .SYNOPSIS
        Forces a logoff of active user sessions on a remote computer.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )
    process {
        # Win32Shutdown flag 4 = Force Logoff
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction Stop
        Invoke-CimMethod -InputObject $os -MethodName Win32Shutdown -Arguments @{Flags=[int]4; Reserved=0} | Out-Null
        return "[OK] Forced logoff initiated on $ComputerName."
    }
}
