function Get-ComputerNetwork {
    <#
    .SYNOPSIS
        Retrieves network adapter configuration from a remote computer using CIM.
    .DESCRIPTION
        Opens a single CimSession and closes it in the finally block.
        Adheres to: cim_session.* ALWAYS reuse-before-create (CONTRACTS)
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [switch]$OnlyIPEnabled
    )

    process {
        $CimSession = $null
        try {
        . $PSScriptRoot\Get-LocalOrRemoteCimSession.ps1
        $CimSession = Get-LocalOrRemoteCimSession -ComputerName $ComputerName

            $filter   = if ($OnlyIPEnabled) { "IPEnabled = True" } else { $null }
            $adapters = Get-CimInstance -CimSession $CimSession -ClassName Win32_NetworkAdapterConfiguration `
                            -Filter $filter -ErrorAction Stop

            $results = foreach ($a in $adapters) {
                [PSCustomObject]@{
                    Description      = $a.Description
                    IPAddress        = $a.IPAddress        -join ", "
                    IPSubnet         = $a.IPSubnet         -join ", "
                    DefaultIPGateway = $a.DefaultIPGateway -join ", "
                    MACAddress       = $a.MACAddress
                    DHCPEnabled      = $a.DHCPEnabled
                    DHCPServer       = $a.DHCPServer
                    DNSHostName      = $a.DNSHostName
                }
            }

            return $results | Sort-Object Description
        }
        catch {
            Write-Warning "Error retrieving network info on $ComputerName`: $($_.Exception.Message)"
            return $null
        }
        finally {
            if ($null -ne $CimSession) {
                Remove-CimSession -CimSession $CimSession -ErrorAction SilentlyContinue
            }
        }
    }
}
