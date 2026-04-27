function Get-ComputerSoftware {
    <#
    .SYNOPSIS
        Retrieves installed software from a remote computer via registry enumeration.
    .DESCRIPTION
        Uses StdRegProv via CIM to read Uninstall keys from HKLM.
        This avoids Win32_Product which triggers an MSI consistency check on every query.
        Adheres to: software.* ALWAYS use-registry-enumeration (CONTRACTS)
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [string]$Search
    )

    process {
        try {
            $hive    = [UInt32]2147483650  # HKLM
            $isLocal = $ComputerName -iin @('localhost', '127.0.0.1', $env:COMPUTERNAME)

            $regParams = @{ Namespace = "root\default"; ClassName = "StdRegProv"; ErrorAction = "Stop" }
            if (-not $isLocal) { $regParams.ComputerName = $ComputerName }
            $reg = Get-CimInstance @regParams

            $uninstallPaths = @(
                "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
                "SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
            )

            $seen   = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            $results = [System.Collections.Generic.List[PSCustomObject]]::new()

            foreach ($path in $uninstallPaths) {
                $enumResult = Invoke-CimMethod -InputObject $reg -MethodName "EnumKey" `
                    -Arguments @{ hDefKey = $hive; sSubKeyName = $path }

                if ($enumResult.ReturnValue -ne 0 -or -not $enumResult.sNames) { continue }

                foreach ($keyName in $enumResult.sNames) {
                    $subPath = "$path\$keyName"

                    $nameResult = Invoke-CimMethod -InputObject $reg -MethodName "GetStringValue" `
                        -Arguments @{ hDefKey = $hive; sSubKeyName = $subPath; sValueName = "DisplayName" }

                    if ($nameResult.ReturnValue -ne 0 -or [string]::IsNullOrWhiteSpace($nameResult.sValue)) { continue }
                    $displayName = $nameResult.sValue

                    # Deduplicate across both registry hives
                    if (-not $seen.Add($displayName)) { continue }

                    # Apply SoftwareRegistry search filter (contract: SoftwareRegistry is the canonical filter term)
                    if ($Search -and $displayName -notlike "*$Search*") { continue }

                    $verResult  = Invoke-CimMethod -InputObject $reg -MethodName "GetStringValue" `
                        -Arguments @{ hDefKey = $hive; sSubKeyName = $subPath; sValueName = "DisplayVersion" }
                    $pubResult  = Invoke-CimMethod -InputObject $reg -MethodName "GetStringValue" `
                        -Arguments @{ hDefKey = $hive; sSubKeyName = $subPath; sValueName = "Publisher" }
                    $dateResult = Invoke-CimMethod -InputObject $reg -MethodName "GetStringValue" `
                        -Arguments @{ hDefKey = $hive; sSubKeyName = $subPath; sValueName = "InstallDate" }

                    $installDate = "Unknown"
                    if ($dateResult.ReturnValue -eq 0 -and $dateResult.sValue) {
                        try {
                            $installDate = [DateTime]::ParseExact($dateResult.sValue, "yyyyMMdd", $null).ToString("yyyy-MM-dd")
                        }
                        catch {
                            $installDate = $dateResult.sValue
                        }
                    }

                    $results.Add([PSCustomObject]@{
                        Name        = $displayName
                        Version     = if ($verResult.ReturnValue  -eq 0) { $verResult.sValue  } else { "" }
                        Vendor      = if ($pubResult.ReturnValue  -eq 0) { $pubResult.sValue  } else { "" }
                        InstallDate = $installDate
                    })
                }
            }

            return $results | Sort-Object Name
        }
        catch {
            Write-Warning "Error retrieving software on $ComputerName`: $_"
            return $null
        }
    }
}
