function Get-ComputerUptime {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string]$ComputerName = "localhost"
    )

    process {
        try {
            $isLocal   = $ComputerName -iin @('localhost', '127.0.0.1', $env:COMPUTERNAME)
            $cimParams = @{ ClassName = "Win32_OperatingSystem"; ErrorAction = "Stop" }
            if (-not $isLocal) { $cimParams.ComputerName = $ComputerName }
            $cim = Get-CimInstance @cimParams
            
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
            Write-Warning "Error getting uptime for $ComputerName`: $($_.Exception.Message)"
            return "Error"
        }
    }
}