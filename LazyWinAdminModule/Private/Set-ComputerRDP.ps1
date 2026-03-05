function Set-ComputerRDP {
    <#
    .SYNOPSIS
        Enables or Disables Remote Desktop on a remote computer using CIM.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [Parameter(Mandatory=$true)]
        [bool]$Enabled
    )

    process {
        try {
            $ts = Get-CimInstance -ComputerName $ComputerName -Namespace "root\cimv2\TerminalServices" -ClassName Win32_TerminalServiceSetting -ErrorAction Stop
            
            # 0 = Enabled, 1 = Disabled
            $allowValue = if ($Enabled) { 0 } else { 1 }
            
            $ts | Set-CimInstance -Property @{ AllowAnyCustomConnect = $allowValue } -ErrorAction Stop
            
            # Also set the Win32_TerminalServiceSetting.SetAllowTSConnections method if needed,
            # but usually setting the property is enough for the registry.
            # We also need to enable the firewall rule if enabling RDP.
            if ($Enabled) {
                Invoke-CimMethod -ComputerName $ComputerName -Namespace "root\cimv2\TerminalServices" -ClassName Win32_TerminalServiceSetting -MethodName "SetAllowTSConnections" -Arguments @{AllowTSConnections=1; ModifyFirewallException=1} | Out-Null
                return "RDP Enabled on $ComputerName"
            } else {
                Invoke-CimMethod -ComputerName $ComputerName -Namespace "root\cimv2\TerminalServices" -ClassName Win32_TerminalServiceSetting -MethodName "SetAllowTSConnections" -Arguments @{AllowTSConnections=0; ModifyFirewallException=0} | Out-Null
                return "RDP Disabled on $ComputerName"
            }
        }
        catch {
            Write-Warning "Error setting RDP status on $ComputerName`: $_"
            return "Error: $_"
        }
    }
}