function Get-ComputerLocalUser {
    <#
    .SYNOPSIS
        Retrieves local user accounts from a local or remote computer using CIM.

    .DESCRIPTION
        Queries the Win32_UserAccount CIM class with a filter of LocalAccount = True
        so that domain accounts mirrored into the local SAM are excluded.

        The Password property is intentionally omitted from the returned objects.
        Even though Win32_UserAccount does not expose the actual password hash,
        excluding it makes the security boundary explicit and prevents any future
        CIM class changes from accidentally surfacing credential material.

        When ComputerName resolves to the local machine (localhost, 127.0.0.1,
        or $env:COMPUTERNAME) no CIM ComputerName parameter is sent, avoiding
        an unnecessary remote-protocol hop.

    .PARAMETER ComputerName
        The hostname or IP address of the target computer.
        Defaults to "localhost" (the local machine).
        Accepts pipeline input.

    .OUTPUTS
        System.Management.Automation.PSCustomObject[]
        An array of selected Win32_UserAccount objects with the following properties:
            Name, FullName, Disabled, Lockout, PasswordRequired, PasswordExpires,
            SID, Status
        The Password property is intentionally excluded for security.
        Returns $null if the query fails.

    .EXAMPLE
        Get-ComputerLocalUser
        Returns all local user accounts on the local machine.

    .EXAMPLE
        Get-ComputerLocalUser -ComputerName "WORKSTATION42"
        Returns all local user accounts on WORKSTATION42.

    .EXAMPLE
        "SERVER01","SERVER02" | Get-ComputerLocalUser
        Returns local user accounts for each computer in the pipeline.
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string]$ComputerName = "localhost"
    )

    process {
        try {
            $isLocal   = $ComputerName -iin @('localhost', '127.0.0.1', $env:COMPUTERNAME)
            $cimParams = @{ ClassName = "Win32_UserAccount"; Filter = "LocalAccount = True"; ErrorAction = "Stop" }
            if (-not $isLocal) { $cimParams.ComputerName = $ComputerName }
            $users = Get-CimInstance @cimParams
            return $users | Select-Object Name, FullName, Disabled, Lockout, PasswordRequired, PasswordExpires, SID, Status
        }
        catch {
            Write-Warning "Error getting local users for $ComputerName`: $_"
            return $null
        }
    }
}
