function Get-ComputerHardware {
    <#
    .SYNOPSIS
        Retrieves hardware information (System, CPU, RAM, Disks) from a local or remote computer.

    .DESCRIPTION
        Opens a single CimSession and reuses it for all queries within the call.
        Adheres to: cim_session.* ALWAYS reuse-before-create (CONTRACTS)

        The following CIM classes are queried over the shared session:
            Win32_ComputerSystem   — model, manufacturer
            Win32_OperatingSystem  — OS caption and version
            Win32_Bios             — serial number
            Win32_Processor        — CPU name and core count (one object per socket)
            Win32_PhysicalMemory   — installed RAM sticks; capacities summed to total GB
            Win32_LogicalDisk      — fixed local drives (DriveType = 3) with size/free space

        RAM is converted from bytes to GB using the [Math]::Round(..., 2) overload, so
        the result is always rounded to two decimal places.
        Disk percentages are likewise rounded to two decimal places.

    .PARAMETER ComputerName
        The hostname or IP address of the target computer. This parameter is mandatory
        because the function is typically called from a dispatcher that always supplies
        the target explicitly.

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        A single object with the following properties:
            Model        [string]   — from Win32_ComputerSystem.Model
            Manufacturer [string]   — from Win32_ComputerSystem.Manufacturer
            RAM_GB       [double]   — total installed RAM in gigabytes, rounded to 2 d.p.
            CPU          [string]   — comma-separated list of "<Name> (<Cores> Cores)" per socket
            OS           [string]   — from Win32_OperatingSystem.Caption
            OS_Version   [string]   — from Win32_OperatingSystem.Version
            SerialNumber [string]   — from Win32_Bios.SerialNumber
            Disks        [PSCustomObject[]] — one entry per fixed drive, each with:
                             DeviceID, SizeGB, FreeGB, PercentFree
        Returns $null if any CIM query fails.

    .EXAMPLE
        Get-ComputerHardware -ComputerName "localhost"
        Returns hardware details for the local machine.

    .EXAMPLE
        Get-ComputerHardware -ComputerName "SERVER01"
        Returns hardware details for SERVER01.

    .EXAMPLE
        $hw = Get-ComputerHardware -ComputerName "SERVER01"
        $hw.Disks | Where-Object PercentFree -lt 10
        Retrieves hardware info and then filters for disks with less than 10% free space.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )

    process {
        $CimSession = $null
        try {
            $isLocal    = $ComputerName -iin @('localhost', '127.0.0.1', $env:COMPUTERNAME)
            $CimSession = if ($isLocal) { New-CimSession -ErrorAction Stop } else { New-CimSession -ComputerName $ComputerName -ErrorAction Stop }

            $cs   = Get-CimInstance -CimSession $CimSession -ClassName Win32_ComputerSystem    -ErrorAction Stop
            $os   = Get-CimInstance -CimSession $CimSession -ClassName Win32_OperatingSystem   -ErrorAction Stop
            $bios = Get-CimInstance -CimSession $CimSession -ClassName Win32_Bios              -ErrorAction Stop

            $cpus     = Get-CimInstance -CimSession $CimSession -ClassName Win32_Processor       -ErrorAction Stop
            $cpuInfo  = $cpus | ForEach-Object { "$($_.Name) ($($_.NumberOfCores) Cores)" }

            $mem          = Get-CimInstance -CimSession $CimSession -ClassName Win32_PhysicalMemory -ErrorAction Stop
            $totalRamBytes = ($mem | Measure-Object -Property Capacity -Sum).Sum
            $totalRamGB    = [Math]::Round($totalRamBytes / 1GB, 2)

            # DriveType 3 = local fixed disk; excludes removable, network, CD-ROM, and RAM drives
            $disks = Get-CimInstance -CimSession $CimSession -ClassName Win32_LogicalDisk `
                        -Filter "DriveType=3" -ErrorAction Stop

            $diskResults = foreach ($d in $disks) {
                [PSCustomObject]@{
                    DeviceID    = $d.DeviceID
                    SizeGB      = [Math]::Round($d.Size      / 1GB, 2)
                    FreeGB      = [Math]::Round($d.FreeSpace / 1GB, 2)
                    PercentFree = [Math]::Round(($d.FreeSpace / $d.Size) * 100, 2)
                }
            }

            return [PSCustomObject]@{
                Model        = $cs.Model
                Manufacturer = $cs.Manufacturer
                RAM_GB       = $totalRamGB
                CPU          = $cpuInfo -join ", "
                OS           = $os.Caption
                OS_Version   = $os.Version
                SerialNumber = $bios.SerialNumber
                Disks        = $diskResults
            }
        }
        catch {
            Write-Warning "Error retrieving hardware on $ComputerName`: $_"
            return $null
        }
        finally {
            if ($null -ne $CimSession) {
                Remove-CimSession -CimSession $CimSession -ErrorAction SilentlyContinue
            }
        }
    }
}
