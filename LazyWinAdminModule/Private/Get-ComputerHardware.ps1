function Get-ComputerHardware {
    <#
    .SYNOPSIS
        Retrieves hardware information (System, CPU, RAM, Disks) from a remote computer.
    .DESCRIPTION
        Opens a single CimSession and reuses it for all queries within the call.
        Adheres to: cim_session.* ALWAYS reuse-before-create (CONTRACTS)
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
