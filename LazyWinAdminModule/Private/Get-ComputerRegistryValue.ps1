function Get-ComputerRegistryValue {
    <#
    .SYNOPSIS
        Reads a single string registry value from a local or remote computer via CIM/StdRegProv.
    .DESCRIPTION
        Uses the StdRegProv CIM class (root\default namespace) to retrieve a string registry
        value without requiring direct registry access or WinRM for localhost.

        For localhost ($ComputerName matches 'localhost', '127.0.0.1', or $env:COMPUTERNAME),
        the CIM instance is obtained locally to avoid an unnecessary WinRM round-trip.
        For remote targets, the CIM instance is created with -ComputerName so the call routes
        through DCOM/WinRM as appropriate.

        This function reads string values only (GetStringValue). It is intentionally limited to
        read-only string access; use Invoke-ComputerRegistry for write operations or for reading
        DWORD/QWord values.

        Avoids Win32_Product and Get-ItemProperty so it is safe on locked-down or remote hosts.
    .PARAMETER ComputerName
        Hostname or IP address of the target computer. Use 'localhost' or '.' for the local machine.
    .PARAMETER Hive
        Registry hive abbreviation. Valid values: HKLM, HKU, HKCU, HKCR, HKCC.
    .PARAMETER KeyPath
        Registry key path relative to the hive root, e.g. 'SOFTWARE\Microsoft\Windows NT\CurrentVersion'.
    .PARAMETER ValueName
        Name of the string value to retrieve. Pass an empty string or omit to read the default value.
    .OUTPUTS
        System.String — the string value stored at the specified key/value, or $null if the value
        does not exist, the key cannot be found, or an error occurs.
    .EXAMPLE
        Get-ComputerRegistryValue -ComputerName 'localhost' -Hive HKLM `
            -KeyPath 'SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ValueName 'ProductName'
        # Returns e.g. 'Windows 11 Enterprise'
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [Parameter(Mandatory=$true)]
        [ValidateSet("HKLM", "HKU", "HKCU", "HKCR", "HKCC")]
        [string]$Hive,

        [Parameter(Mandatory=$true)]
        [string]$KeyPath,

        [string]$ValueName
    )

    process {
        try {
            $hives = @{
                "HKCR" = 2147483648
                "HKCU" = 2147483649
                "HKLM" = 2147483650
                "HKU"  = 2147483651
                "HKCC" = 2147483652
            }

            $hDefKey = $hives[$Hive]

            # Use CIM to call StdRegProv methods (Firewall friendly)
            $params = @{
                hDefKey     = $hDefKey
                sSubKeyName = $KeyPath
                sValueName  = $ValueName
            }

            $isLocal   = $ComputerName -iin @('localhost', '127.0.0.1', $env:COMPUTERNAME)
            $cimParams = @{ Namespace = "root\default"; ClassName = "StdRegProv"; ErrorAction = "Stop" }
            if (-not $isLocal) { $cimParams.ComputerName = $ComputerName }
            $reg = Get-CimInstance @cimParams

            $result = Invoke-CimMethod -InputObject $reg -MethodName "GetStringValue" -Arguments $params -ErrorAction Stop

            if ($result.ReturnValue -eq 0) {
                return $result.sValue
            }
            else {
                Write-Verbose "Registry value not found or error code: $($result.ReturnValue)"
                return $null
            }
        }
        catch {
            Write-Warning "Error reading registry on $ComputerName`: $_"
            return $null
        }
    }
}
