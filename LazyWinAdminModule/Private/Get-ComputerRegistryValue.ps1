function Get-ComputerRegistryValue {
    <#
    .SYNOPSIS
        Retrieves a registry value from a remote computer using CIM (WMI over WinRM).
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
            hDefKey = $hDefKey
            sSubKeyName = $KeyPath
            sValueName = $ValueName
        }

        $result = Invoke-CimMethod -ComputerName $ComputerName -Namespace "root\default" -ClassName "StdRegProv" -MethodName "GetStringValue" -Arguments $params -ErrorAction Stop
        
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