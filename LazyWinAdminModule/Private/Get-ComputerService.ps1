function Get-ComputerService {
    <#
    .SYNOPSIS
        Retrieves service information from a remote computer using CIM.
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string]$ComputerName = "localhost",

        [string]$Name,

        [switch]$OnlyAutoStopped
    )

    process {
        . $PSScriptRoot\Get-LocalOrRemoteCimSession.ps1
        try {
            $CimSession = Get-LocalOrRemoteCimSession -ComputerName $ComputerName

            $filter = ""
            if ($Name) {
                $filter = "Name = '$Name'"
            }
            elseif ($OnlyAutoStopped) {
                $filter = "StartMode = 'Auto' AND State != 'Running'"
            }

            $params = @{
                ClassName   = "Win32_Service"
                CimSession  = $CimSession
                ErrorAction = "Stop"
            }
            if ($filter)    { $params.Filter       = $filter       }

            $services = Get-CimInstance @params
            
            return $services | Select-Object Name, DisplayName, State, StartMode, StartName, ProcessId
        }
        catch {
            Write-Warning "Error getting services for $ComputerName`: $($_.Exception.Message)"
            return $null
        }
        finally {
            if ($CimSession) { Remove-CimSession $CimSession -ErrorAction SilentlyContinue }
        }
    }
}