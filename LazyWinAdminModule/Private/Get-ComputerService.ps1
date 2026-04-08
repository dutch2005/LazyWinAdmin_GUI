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
        try {
            $isLocal = $ComputerName -iin @('localhost', '127.0.0.1', $env:COMPUTERNAME)

            $filter = ""
            if ($Name) {
                $filter = "Name = '$Name'"
            }
            elseif ($OnlyAutoStopped) {
                $filter = "StartMode = 'Auto' AND State != 'Running'"
            }

            $params = @{
                ClassName   = "Win32_Service"
                ErrorAction = "Stop"
            }
            if ($filter)    { $params.Filter       = $filter       }
            if (-not $isLocal) { $params.ComputerName = $ComputerName }

            $services = Get-CimInstance @params
            
            return $services | Select-Object Name, DisplayName, State, StartMode, StartName, ProcessId
        }
        catch {
            Write-Warning "Error getting services for $ComputerName`: $_"
            return $null
        }
    }
}