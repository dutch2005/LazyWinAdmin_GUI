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

    try {
        $users = Get-CimInstance -ClassName Win32_UserAccount -Filter "LocalAccount = True" -ComputerName $ComputerName -ErrorAction Stop
        return $users | Select-Object Name, FullName, Disabled, Lockout, PasswordRequired, PasswordExpires, SID, Status
    }
    catch {
        Write-Warning "Error getting local users for $ComputerName`: $_"
        return $null
    }
}