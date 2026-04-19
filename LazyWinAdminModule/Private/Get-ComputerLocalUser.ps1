function Get-ComputerLocalUser {
    <#
    .SYNOPSIS
        Retrieves local user accounts from a remote computer using CIM.
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