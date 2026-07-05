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
        . $PSScriptRoot\Get-LocalOrRemoteCimSession.ps1
        try {
            $CimSession = Get-LocalOrRemoteCimSession -ComputerName $ComputerName
            $cimParams = @{ ClassName = "Win32_Group"; Filter = "LocalAccount = True"; CimSession = $CimSession; ErrorAction = "Stop" }
            $groups = Get-CimInstance @cimParams
            return $groups | Select-Object Name, Caption, SID, Status
        }
        catch {
            Write-Warning "Error getting local groups for $ComputerName`: $($_.Exception.Message)"
            return $null
        }
        finally {
            if ($CimSession) { Remove-CimSession $CimSession -ErrorAction SilentlyContinue }
        }
    }
}