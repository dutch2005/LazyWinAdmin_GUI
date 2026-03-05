function Get-ComputerMotherboard {
    <#
    .SYNOPSIS
        Retrieves motherboard information from a remote computer using CIM.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )

    process {
        try {
            $baseBoard = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_BaseBoard -ErrorAction Stop
            
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
    }
}