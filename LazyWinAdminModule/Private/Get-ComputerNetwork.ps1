function Get-ComputerNetwork {
    <#
    .SYNOPSIS
        Retrieves network adapter configuration from a local or remote computer using CIM.

    .DESCRIPTION
        Opens a single CimSession and closes it in the finally block.
        Adheres to: cim_session.* ALWAYS reuse-before-create (CONTRACTS)

        Queries Win32_NetworkAdapterConfiguration for all adapters, or only those
        with IP enabled when -OnlyIPEnabled is specified. Multi-valued properties
        (IPAddress, IPSubnet, DefaultIPGateway) are joined into comma-separated
        strings so that the output objects are easily displayable in a grid or table.

        Results are sorted alphabetically by Description so that the presentation
        order is stable across successive calls.

    .PARAMETER ComputerName
        The hostname or IP address of the target computer. This parameter is mandatory
        because the function is typically called from a dispatcher that always supplies
        the target explicitly.

    .PARAMETER OnlyIPEnabled
        When set, the CIM query is filtered to Win32_NetworkAdapterConfiguration
        instances where IPEnabled = True. This excludes virtual adapters,
        loopback adapters, and other interfaces that have no bound IP stack.

    .OUTPUTS
        System.Management.Automation.PSCustomObject[]
        An array of adapter objects sorted by Description, each with the following
        properties:
            Description      [string]  — adapter name / friendly description
            IPAddress        [string]  — comma-separated list of assigned IP addresses
            IPSubnet         [string]  — comma-separated list of subnet masks
            DefaultIPGateway [string]  — comma-separated list of gateway addresses
            MACAddress       [string]  — hardware MAC address
            DHCPEnabled      [bool]    — whether DHCP is active on this adapter
            DHCPServer       [string]  — DHCP server address (if applicable)
            DNSHostName      [string]  — DNS hostname registered by this adapter
        Returns $null if the CIM query fails.

    .EXAMPLE
        Get-ComputerNetwork -ComputerName "localhost"
        Returns all network adapter configurations on the local machine.

    .EXAMPLE
        Get-ComputerNetwork -ComputerName "SERVER01" -OnlyIPEnabled
        Returns only IP-enabled adapters on SERVER01.

    .EXAMPLE
        Get-ComputerNetwork -ComputerName "SERVER01" | Where-Object DHCPEnabled -eq $false
        Returns adapters that are statically configured on SERVER01.
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
            $isLocal    = $ComputerName -iin @('localhost', '127.0.0.1', $env:COMPUTERNAME)
            $CimSession = if ($isLocal) { New-CimSession -ErrorAction Stop } else { New-CimSession -ComputerName $ComputerName -ErrorAction Stop }

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
            Write-Warning "Error retrieving network info on $ComputerName`: $_"
            return $null
        }
        finally {
            if ($null -ne $CimSession) {
                Remove-CimSession -CimSession $CimSession -ErrorAction SilentlyContinue
            }
        }
    }
}
