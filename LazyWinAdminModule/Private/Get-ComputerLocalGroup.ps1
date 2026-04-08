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

    process {
        try {
            $isLocal   = $ComputerName -iin @('localhost', '127.0.0.1', $env:COMPUTERNAME)
            $cimParams = @{ ClassName = "Win32_Group"; Filter = "LocalAccount = True"; ErrorAction = "Stop" }
            if (-not $isLocal) { $cimParams.ComputerName = $ComputerName }
            $groups = Get-CimInstance @cimParams
            return $groups | Select-Object Name, Caption, SID, Status
        }
        catch {
            Write-Warning "Error getting local groups for $ComputerName`: $_"
            return $null
        }
    }
}