function Get-ComputerUptime {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string]$ComputerName = "localhost"
    )

    try {
        # Replaced deprecated Get-WmiObject with Get-CimInstance (uses WSMan/WinRM)
        $cim = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction Stop
        
        # CIM natively returns a DateTime object for LastBootUpTime, no need to convert like WMI
        if ($cim -and $cim.LastBootUpTime) {
            $LBTime = $cim.LastBootUpTime
            $uptime = New-TimeSpan -Start $LBTime -End (Get-Date)
            
            $days = $uptime.Days
            $hours = $uptime.Hours
            $minutes = $uptime.Minutes
            $seconds = $uptime.Seconds
            
            return "$days Days $hours Hours $minutes Minutes $seconds Seconds"
        }
        return "Unknown"
    }
    catch {
        Write-Warning "Error getting uptime for $ComputerName`: $_"
        return "Error"
    }
}