function Restart-LWAPrintSpooler {
    <#
    .SYNOPSIS
        Restarts the Print Spooler service on a local or remote computer via CIM.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )
    process {
        $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='Spooler'" -ComputerName $ComputerName -ErrorAction Stop
        if (-not $service) { throw "Print Spooler service not found on $ComputerName." }
        
        Invoke-CimMethod -InputObject $service -MethodName StopService | Out-Null
        Start-Sleep -Seconds 2
        Invoke-CimMethod -InputObject $service -MethodName StartService | Out-Null
        return "[OK] Print Spooler restarted on $ComputerName."
    }
}
