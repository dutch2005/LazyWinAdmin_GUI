function Get-ComputerLocalGroup {
    <#
    .SYNOPSIS
        Retrieves local groups from a remote computer using CIM.
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string]$ComputerName = "localhost"
    )

    try {
        $groups = Get-CimInstance -ClassName Win32_Group -Filter "LocalAccount = True" -ComputerName $ComputerName -ErrorAction Stop
        return $groups | Select-Object Name, Caption, SID, Status
    }
    catch {
        Write-Warning "Error getting local groups for $ComputerName`: $_"
        return $null
    }
}