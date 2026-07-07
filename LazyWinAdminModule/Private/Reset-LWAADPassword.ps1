function Reset-LWAADPassword {
    <#
    .SYNOPSIS
        Resets the password for an Active Directory user account.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$SamAccountName,
        [Parameter(Mandatory=$true)]
        [SecureString]$NewPassword,
        [switch]$ForceChangeOnLogon
    )
    process {
        if (-not (Get-Module ActiveDirectory -ListAvailable)) { throw "ActiveDirectory module missing." }
        Import-Module ActiveDirectory -ErrorAction Stop
        Set-ADAccountPassword -Identity $SamAccountName -NewPassword $NewPassword -Reset -ErrorAction Stop
        if ($ForceChangeOnLogon) {
            Set-ADUser -Identity $SamAccountName -ChangePasswordAtLogon $true -ErrorAction Stop
        }
        return "[OK] Password reset successfully for $SamAccountName."
    }
}
