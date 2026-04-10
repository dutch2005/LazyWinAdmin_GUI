function Get-ComputerService {
    <#
    .SYNOPSIS
        Retrieves service information from a local or remote computer using CIM.

    .DESCRIPTION
        Queries the Win32_Service CIM class to return a filtered view of services.
        When ComputerName resolves to the local machine (localhost, 127.0.0.1, or
        $env:COMPUTERNAME) no CIM ComputerName parameter is sent, avoiding an
        unnecessary DCOM/WSMan hop.

        Filtering priority:
          1. If -Name is supplied, only the named service is returned.
          2. Else if -OnlyAutoStopped is set, only services whose StartMode is
             'Auto' and current State is not 'Running' are returned.
          3. If neither switch is provided, all services are returned.

        Note: -Name and -OnlyAutoStopped are mutually exclusive by convention;
        -Name takes precedence when both are specified.

    .PARAMETER ComputerName
        The hostname or IP address of the target computer.
        Defaults to "localhost" (the local machine).
        Accepts pipeline input.

    .PARAMETER Name
        Optional. The exact Win32_Service.Name of a single service to retrieve.
        When supplied, the -OnlyAutoStopped switch is ignored.

    .PARAMETER OnlyAutoStopped
        When set, restricts results to services that are configured to start
        automatically (StartMode = 'Auto') but are not currently running
        (State != 'Running'). Useful for identifying services that should be
        running but have stopped unexpectedly.

    .OUTPUTS
        System.Management.Automation.PSCustomObject[]
        An array of selected Win32_Service objects with the following properties:
            Name, DisplayName, State, StartMode, StartName, ProcessId
        Returns $null if the query fails.

    .EXAMPLE
        Get-ComputerService
        Returns all services on the local machine.

    .EXAMPLE
        Get-ComputerService -ComputerName "SERVER01" -OnlyAutoStopped
        Returns all automatic-start services that are not running on SERVER01.

    .EXAMPLE
        Get-ComputerService -ComputerName "SERVER01" -Name "wuauserv"
        Returns details for the Windows Update service on SERVER01.

    .EXAMPLE
        "SERVER01","SERVER02" | Get-ComputerService -OnlyAutoStopped
        Pipes multiple computer names and returns stopped auto-start services for each.
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
