function Get-ComputerMotherboard {
    <#
    .SYNOPSIS
        Retrieves motherboard information from a remote computer using CIM.
    .DESCRIPTION
        Opens a single CimSession and closes it in the finally block.
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
