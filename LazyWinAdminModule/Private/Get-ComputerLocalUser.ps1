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
        . $PSScriptRoot\Get-LocalOrRemoteCimSession.ps1
        try {
            $CimSession = Get-LocalOrRemoteCimSession -ComputerName $ComputerName
            $cimParams = @{ ClassName = "Win32_UserAccount"; Filter = "LocalAccount = True"; CimSession = $CimSession; ErrorAction = "Stop" }
            $users = Get-CimInstance @cimParams
            return $users | Select-Object Name, FullName, Disabled, Lockout, PasswordRequired, PasswordExpires, SID, Status
        }
        catch {
            Write-Warning "Error getting local users for $ComputerName`: $($_.Exception.Message)"
            return $null
        }
        finally {
            if ($CimSession) { Remove-CimSession $CimSession -ErrorAction SilentlyContinue }
        }
    }
}