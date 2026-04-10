function Get-ComputerUptime {
    <#
    .SYNOPSIS
        Returns the uptime of a local or remote computer as a human-readable string.

    .DESCRIPTION
        Queries Win32_OperatingSystem via CIM to retrieve the LastBootUpTime
        property, then computes the elapsed time relative to the current clock.
        CIM natively deserialises LastBootUpTime as a [DateTime] object, so no
        manual WMI DMTF-string conversion is required.

        When ComputerName resolves to the local machine (localhost, 127.0.0.1,
        or $env:COMPUTERNAME) no CIM ComputerName parameter is sent, avoiding
        an unnecessary remote-protocol hop.

    .PARAMETER ComputerName
        The hostname or IP address of the target computer.
        Defaults to "localhost" (the local machine).
        Accepts pipeline input.

    .OUTPUTS
        System.String
        A formatted uptime string: "<D> Days <H> Hours <M> Minutes <S> Seconds"
        Returns "Unknown" if LastBootUpTime is not available.
        Returns "Error" if the CIM query throws an exception.

    .EXAMPLE
        Get-ComputerUptime
        Returns the uptime of the local machine, e.g. "3 Days 4 Hours 22 Minutes 10 Seconds".

    .EXAMPLE
        Get-ComputerUptime -ComputerName "SERVER01"
        Returns the uptime string for SERVER01.

    .EXAMPLE
        "SERVER01","SERVER02" | Get-ComputerUptime
        Returns the uptime string for each computer in the pipeline.
    #>
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
            Write-Warning "Error getting uptime for $ComputerName`: $_"
            return "Error"
        }
    }
}
