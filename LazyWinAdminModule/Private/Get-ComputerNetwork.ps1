function Get-ComputerNetwork {
    <#
    .SYNOPSIS
        Retrieves network adapter configuration from a remote computer using CIM.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [switch]$OnlyIPEnabled
    )

    process {
        try {
            $filter = if ($OnlyIPEnabled) { "IPEnabled = True" } else { $null }
            $adapters = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_NetworkAdapterConfiguration -Filter $filter -ErrorAction Stop
            
            $results = foreach ($a in $adapters) {
                [PSCustomObject]@{
                    Description      = $a.Description
                    IPAddress        = $a.IPAddress -join ", "
                    IPSubnet         = $a.IPSubnet -join ", "
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
            Write-Warning "Error retrieving network info on $ComputerName`: $_"
            return $null
        }
    }
}