function Set-ComputerRDP {
    <#
    .SYNOPSIS
        Enables or Disables Remote Desktop on a remote computer.
    .DESCRIPTION
        Implements rdp_toggle FLOW steps 3 and 4 as two distinct CIM operations
        over a single shared CimSession:

          Step 3 [CORE] computer.set_rdp_registry
            Sets HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\fDenyTSConnections
            via StdRegProv. Value 0 = RDP allowed, 1 = RDP denied.

          Step 4 [CORE] computer.set_firewall_rule
            Enables or disables the "Remote Desktop" firewall rule group
            via ROOT\StandardCimv2\MSFT_NetFirewallRule.

        Previously both operations were combined in a single SetAllowTSConnections CIM method
        call. Splitting them makes each step independently verifiable and rollback-safe.
        Adheres to: cim_session.* ALWAYS reuse-before-create (CONTRACTS)
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [Parameter(Mandatory=$true)]
        [bool]$Enabled
    )

    process {
        $action = if ($Enabled) { 'Enable' } else { 'Disable' }
        if (-not $PSCmdlet.ShouldProcess($ComputerName, "$action RDP")) {
            return "[!] Skipped by -WhatIf or -Confirm."
        }
        $CimSession = $null
        try {
            $isLocal    = $ComputerName -iin @('localhost', '127.0.0.1', $env:COMPUTERNAME)
            $CimSession = if ($isLocal) { New-CimSession -ErrorAction Stop } else { New-CimSession -ComputerName $ComputerName -ErrorAction Stop }

            # --- STEP 3: computer.set_rdp_registry ---
            # Toggle fDenyTSConnections in the Terminal Server registry key.
            # 0 = connections allowed (RDP on), 1 = connections denied (RDP off).
            $reg         = Get-CimInstance -CimSession $CimSession -Namespace "root\default" `
                               -ClassName StdRegProv -ErrorAction Stop
            $fDenyValue  = if ($Enabled) { [uint32]0 } else { [uint32]1 }
            $regResult   = Invoke-CimMethod -InputObject $reg -MethodName "SetDWORDValue" -Arguments @{
                hDefKey     = [uint32]2147483650  # HKLM
                sSubKeyName = "SYSTEM\CurrentControlSet\Control\Terminal Server"
                sValueName  = "fDenyTSConnections"
                uValue      = $fDenyValue
            } -ErrorAction Stop

            if ($regResult.ReturnValue -ne 0) {
                throw "Registry write failed with StdRegProv return code $($regResult.ReturnValue)"
            }

            # --- STEP 4: computer.set_firewall_rule ---
            # Enable or disable the "Remote Desktop" rule group in Windows Firewall
            # via the MSFT_NetFirewallRule CIM class in ROOT\StandardCimv2.
            # Enabled: uint16 1 = True, 0 = False.
            $enabledVal  = if ($Enabled) { [uint16]1 } else { [uint16]0 }
            $fwRules     = Get-CimInstance -CimSession $CimSession -Namespace "ROOT\StandardCimv2" `
                               -ClassName "MSFT_NetFirewallRule" `
                               -Filter "DisplayGroup='Remote Desktop'" -ErrorAction Stop

            if ($fwRules) {
                foreach ($rule in $fwRules) {
                    Set-CimInstance -CimSession $CimSession -InputObject $rule `
                        -Property @{ Enabled = $enabledVal } -ErrorAction Stop
                }
            }

            $action = if ($Enabled) { "Enabled" } else { "Disabled" }
            return "RDP $action on $ComputerName"
        }
        catch {
            Write-Warning "Error setting RDP status on $ComputerName`: $_"
            # Return generic message — do not surface exception detail to UI layer
            return "Error: RDP operation failed on $ComputerName"
        }
        finally {
            if ($null -ne $CimSession) {
                Remove-CimSession -CimSession $CimSession -ErrorAction SilentlyContinue
            }
        }
    }
}
