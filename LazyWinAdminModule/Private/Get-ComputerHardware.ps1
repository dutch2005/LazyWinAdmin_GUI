function Get-ComputerHardware {
    <#
    .SYNOPSIS
        Retrieves hardware information (System, CPU, RAM, Disks) from a remote computer using CIM.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )

    process {
        try {
            # System Info
            $cs = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem -ErrorAction Stop
            $os = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_OperatingSystem -ErrorAction Stop
            $bios = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_Bios -ErrorAction Stop
            
            # CPU Info
            $cpus = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_Processor -ErrorAction Stop
            $cpuInfo = $cpus | ForEach-Object { "$($_.Name) ($($_.NumberOfCores) Cores)" }
            
            # RAM Info
            $mem = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_PhysicalMemory -ErrorAction Stop
            $totalRamBytes = ($mem | Measure-Object -Property Capacity -Sum).Sum
            $totalRamGB = [Math]::Round($totalRamBytes / 1GB, 2)
            
            # Disk Info
            $disks = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop
            $diskResults = foreach ($d in $disks) {
                [PSCustomObject]@{
                    DeviceID   = $d.DeviceID
                    SizeGB     = [Math]::Round($d.Size / 1GB, 2)
                    FreeGB     = [Math]::Round($d.FreeSpace / 1GB, 2)
                    PercentFree = [Math]::Round(($d.FreeSpace / $d.Size) * 100, 2)
                }
            }

            return [PSCustomObject]@{
                Model       = $cs.Model
                Manufacturer = $cs.Manufacturer
                RAM_GB      = $totalRamGB
                CPU         = $cpuInfo -join ", "
                OS          = $os.Caption
                OS_Version  = $os.Version
                SerialNumber = $bios.SerialNumber
                Disks       = $diskResults
            }
        }
        catch {
            Write-Warning "Error retrieving hardware on $ComputerName`: $_"
            return $null
        }
    }
}