function Invoke-ComputerRegistry {
    <#
    .SYNOPSIS
        Performs registry operations (Get, Set, New, Remove) on a remote computer.
    .DESCRIPTION
        Uses CIM (StdRegProv) for cross-platform compatibility and performance.
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
                "HKCR" = 2147483648
                "HKCU" = 2147483649
                "HKLM" = 2147483650
                "HKU"  = 2147483651
            }
            $hDef = $hives[$Hive]

            $reg = Get-CimInstance -ComputerName $ComputerName -Namespace "root\default" -ClassName StdRegProv -ErrorAction Stop

            switch ($Action) {
                "Get" {
                    $res = Invoke-CimMethod -InputObject $reg -MethodName "GetStringValue" -Arguments @{hDef=$hDef; sSubKeyName=$KeyPath; sValueName=$ValueName}
                    if ($res.ReturnValue -eq 0) { return $res.sValue }
                    
                    # Try DWord if string fails
                    $res = Invoke-CimMethod -InputObject $reg -MethodName "GetDWORDValue" -Arguments @{hDef=$hDef; sSubKeyName=$KeyPath; sValueName=$ValueName}
                    if ($res.ReturnValue -eq 0) { return $res.uValue }
                    
                    return $null
                }
                "Set" {
                    $method = "Set$($ValueType)Value"
                    if ($ValueType -eq "String") { $args = @{hDef=$hDef; sSubKeyName=$KeyPath; sValueName=$ValueName; sValue=[string]$Value} }
                    elseif ($ValueType -eq "DWord") { $args = @{hDef=$hDef; sSubKeyName=$KeyPath; sValueName=$ValueName; uValue=[uint32]$Value} }
                    # Add others as needed
                    
                    $res = Invoke-CimMethod -InputObject $reg -MethodName $method -Arguments $args
                    return ($res.ReturnValue -eq 0)
                }
                "New" {
                    $res = Invoke-CimMethod -InputObject $reg -MethodName "CreateKey" -Arguments @{hDef=$hDef; sSubKeyName=$KeyPath}
                    return ($res.ReturnValue -eq 0)
                }
                "Remove" {
                    if ($ValueName) {
                        $res = Invoke-CimMethod -InputObject $reg -MethodName "DeleteValue" -Arguments @{hDef=$hDef; sSubKeyName=$KeyPath; sValueName=$ValueName}
                    } else {
                        $res = Invoke-CimMethod -InputObject $reg -MethodName "DeleteKey" -Arguments @{hDef=$hDef; sSubKeyName=$KeyPath}
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