function Start-LWAEntraSync {
    <#
    .SYNOPSIS
        Forces an AD Connect (Entra Connect) Delta Sync cycle to push on-prem AD changes to the cloud immediately.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$AadConnectServerName
    )
    process {
        Invoke-Command -ComputerName $AadConnectServerName -ScriptBlock {
            if (Get-Module ADSync -ListAvailable) {
                Import-Module ADSync
                Start-ADSyncSyncCycle -PolicyType Delta
            } else {
                throw "ADSync module is not installed on $env:COMPUTERNAME."
            }
        } -ErrorAction Stop
        return "[OK] Entra ID Delta sync triggered successfully on server $AadConnectServerName."
    }
}
