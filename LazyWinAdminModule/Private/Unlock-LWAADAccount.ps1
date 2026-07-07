function Unlock-LWAADAccount {
    <#
    .SYNOPSIS
        Unlocks an Active Directory user account.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$SamAccountName
    )
    process {
        if (-not (Get-Module ActiveDirectory -ListAvailable)) { throw "ActiveDirectory module missing." }
        Import-Module ActiveDirectory -ErrorAction Stop
        Unlock-ADAccount -Identity $SamAccountName -ErrorAction Stop
        return "[OK] Account $SamAccountName unlocked successfully."
    }
}
