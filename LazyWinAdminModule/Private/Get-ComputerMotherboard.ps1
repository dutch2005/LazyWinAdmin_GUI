function Get-ComputerMotherboard {
    <#
    .SYNOPSIS
        Retrieves motherboard (baseboard) information from a local or remote computer using CIM.

    .DESCRIPTION
        Opens a single CimSession and closes it in the finally block.
        Adheres to: cim_session.* ALWAYS reuse-before-create (CONTRACTS)

        Queries Win32_BaseBoard via the shared CimSession and returns a lightweight
        PSCustomObject containing the four most operationally relevant properties.
        The SerialNumber field is particularly useful for asset-management workflows
        where the chassis serial number (from Win32_Bios) differs from the board serial.

    .PARAMETER ComputerName
        The hostname or IP address of the target computer. This parameter is mandatory
        because the function is typically called from a dispatcher that always supplies
        the target explicitly.

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        A single object with the following properties sourced from Win32_BaseBoard:
            Product      [string] — board product name / model identifier
            Manufacturer [string] — board manufacturer name
            SerialNumber [string] — board serial number (may differ from chassis serial)
            Version      [string] — board version / revision string
        Returns $null if the CIM query fails.

    .EXAMPLE
        Get-ComputerMotherboard -ComputerName "localhost"
        Returns motherboard details for the local machine.

    .EXAMPLE
        Get-ComputerMotherboard -ComputerName "WORKSTATION42"
        Returns motherboard details for WORKSTATION42.

    .EXAMPLE
        $board = Get-ComputerMotherboard -ComputerName "SERVER01"
        "$($board.Manufacturer) $($board.Product) — S/N: $($board.SerialNumber)"
        Formats a one-line summary of the board identity.
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
            $baseBoard   = Get-CimInstance -CimSession $CimSession -ClassName Win32_BaseBoard -ErrorAction Stop

            return [PSCustomObject]@{
                Product      = $baseBoard.Product
                Manufacturer = $baseBoard.Manufacturer
                SerialNumber = $baseBoard.SerialNumber
                Version      = $baseBoard.Version
            }
        }
        catch {
            Write-Warning "Error retrieving motherboard info on $ComputerName`: $_"
            return $null
        }
        finally {
            if ($null -ne $CimSession) {
                Remove-CimSession -CimSession $CimSession -ErrorAction SilentlyContinue
            }
        }
    }
}
