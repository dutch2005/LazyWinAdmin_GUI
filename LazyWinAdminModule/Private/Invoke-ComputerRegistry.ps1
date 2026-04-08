function Invoke-ComputerRegistry {
    <#
    .SYNOPSIS
        Performs registry operations (Get, Set, New, Remove) on a remote computer.
    .DESCRIPTION
        Uses CIM (StdRegProv) for cross-platform compatibility and performance.
        Adheres to: registry_entry.* REQUIRES hive-valid (CONTRACTS)
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Get", "Set", "New", "Remove")]
        [string]$Action,

        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [Parameter(Mandatory=$true)]
        [ValidateSet("HKCR", "HKCU", "HKLM", "HKU")]
        [string]$Hive,

        [Parameter(Mandatory=$true)]
        [string]$KeyPath,

        [string]$ValueName,

        $Value,

        [ValidateSet("String", "ExpandString", "Binary", "DWord", "MultiString", "QWord")]
        [string]$ValueType = "String"
    )

    process {
        try {
            $hives = @{
                "HKCR" = [UInt32]2147483648
                "HKCU" = [UInt32]2147483649
                "HKLM" = [UInt32]2147483650
                "HKU"  = [UInt32]2147483651
            }
            $hDef = $hives[$Hive]

            $isLocal   = $ComputerName -iin @('localhost', '127.0.0.1', $env:COMPUTERNAME)
            $regParams = @{ Namespace = "root\default"; ClassName = "StdRegProv"; ErrorAction = "Stop" }
            if (-not $isLocal) { $regParams.ComputerName = $ComputerName }
            $reg = Get-CimInstance @regParams

            switch ($Action) {
                "Get" {
                    $res = Invoke-CimMethod -InputObject $reg -MethodName "GetStringValue" `
                        -Arguments @{ hDefKey = $hDef; sSubKeyName = $KeyPath; sValueName = $ValueName }
                    if ($res.ReturnValue -eq 0) { return $res.sValue }

                    # Fall back to DWORD if string lookup returns no result
                    $res = Invoke-CimMethod -InputObject $reg -MethodName "GetDWORDValue" `
                        -Arguments @{ hDefKey = $hDef; sSubKeyName = $KeyPath; sValueName = $ValueName }
                    if ($res.ReturnValue -eq 0) { return $res.uValue }

                    return $null
                }
                "Set" {
                    $methodName = "Set$($ValueType)Value"

                    # $cimArgs renamed from $args — $args is a PowerShell automatic variable
                    if ($ValueType -eq "String") {
                        $cimArgs = @{ hDefKey = $hDef; sSubKeyName = $KeyPath; sValueName = $ValueName; sValue = [string]$Value }
                    }
                    elseif ($ValueType -eq "DWord") {
                        $cimArgs = @{ hDefKey = $hDef; sSubKeyName = $KeyPath; sValueName = $ValueName; uValue = [uint32]$Value }
                    }
                    elseif ($ValueType -eq "QWord") {
                        $cimArgs = @{ hDefKey = $hDef; sSubKeyName = $KeyPath; sValueName = $ValueName; uValue = [uint64]$Value }
                    }
                    else {
                        Write-Warning "ValueType '$ValueType' is not yet fully implemented."
                        return $false
                    }

                    $res = Invoke-CimMethod -InputObject $reg -MethodName $methodName -Arguments $cimArgs
                    return ($res.ReturnValue -eq 0)
                }
                "New" {
                    $res = Invoke-CimMethod -InputObject $reg -MethodName "CreateKey" `
                        -Arguments @{ hDefKey = $hDef; sSubKeyName = $KeyPath }
                    return ($res.ReturnValue -eq 0)
                }
                "Remove" {
                    if ($ValueName) {
                        $res = Invoke-CimMethod -InputObject $reg -MethodName "DeleteValue" `
                            -Arguments @{ hDefKey = $hDef; sSubKeyName = $KeyPath; sValueName = $ValueName }
                    }
                    else {
                        $res = Invoke-CimMethod -InputObject $reg -MethodName "DeleteKey" `
                            -Arguments @{ hDefKey = $hDef; sSubKeyName = $KeyPath }
                    }
                    return ($res.ReturnValue -eq 0)
                }
            }
        }
        catch {
            Write-Warning "Registry operation failed on $ComputerName`: $_"
            return $null
        }
    }
}
