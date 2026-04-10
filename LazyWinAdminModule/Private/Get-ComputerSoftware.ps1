function Get-ComputerSoftware {
    <#
    .SYNOPSIS
        Retrieves installed software from a local or remote computer via registry enumeration.

    .DESCRIPTION
        Uses StdRegProv via CIM to read Uninstall keys from HKLM.
        This avoids Win32_Product which triggers an MSI consistency check on every query.
        Adheres to: software.* ALWAYS use-registry-enumeration (CONTRACTS)

        Both the 64-bit and 32-bit (WOW6432Node) Uninstall hive paths are enumerated.
        A case-insensitive HashSet deduplicates entries that appear in both hives so
        each application is reported exactly once. Entries with no DisplayName are
        silently skipped as they represent incomplete or in-progress installs.

        InstallDate values are stored in YYYYMMDD format; the function attempts to
        parse and reformat them as yyyy-MM-dd for readability. If parsing fails the
        raw registry string is returned unchanged.

    .PARAMETER ComputerName
        The hostname or IP address of the target computer. This parameter is mandatory
        because the function is typically called from a dispatcher that always supplies
        the target explicitly.

    .PARAMETER Search
        Optional case-insensitive wildcard filter applied to the DisplayName field.
        Supports standard PowerShell wildcard characters (* and ?).
        Only entries whose DisplayName matches "*$Search*" are included in the output.
        When omitted, all installed applications are returned.

    .OUTPUTS
        System.Management.Automation.PSCustomObject[]
        An array of software objects sorted alphabetically by Name, each with:
            Name        [string] — DisplayName from the registry
            Version     [string] — DisplayVersion from the registry (empty string if absent)
            Vendor      [string] — Publisher from the registry (empty string if absent)
            InstallDate [string] — Formatted as yyyy-MM-dd, raw YYYYMMDD string, or "Unknown"
        Returns $null if the CIM/registry query fails.

    .EXAMPLE
        Get-ComputerSoftware -ComputerName "localhost"
        Returns all installed software on the local machine.

    .EXAMPLE
        Get-ComputerSoftware -ComputerName "WORKSTATION42" -Search "Microsoft"
        Returns all software entries whose DisplayName contains "Microsoft" on WORKSTATION42.

    .EXAMPLE
        Get-ComputerSoftware -ComputerName "SERVER01" | Where-Object Vendor -eq "Adobe Inc."
        Returns all Adobe products installed on SERVER01.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [string]$Search
    )

    process {
        try {
            $hive    = [UInt32]2147483650  # HKLM (HKEY_LOCAL_MACHINE = 0x80000002)
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
