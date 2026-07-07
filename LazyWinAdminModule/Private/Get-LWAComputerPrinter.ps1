function Get-LWAComputerPrinter {
    <#
    .SYNOPSIS
        Retrieves a list of installed printers on a local or remote computer.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )
    process {
        return Get-CimInstance -ClassName Win32_Printer -ComputerName $ComputerName -ErrorAction Stop | 
               Select-Object Name, PortName, DriverName, Default, Shared, PrinterState, PrinterStatus
    }
}
