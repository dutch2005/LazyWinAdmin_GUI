function Get-ComputerLocalGroup {
    <#
    .SYNOPSIS
        Retrieves local security groups from a local or remote computer using CIM.

    .DESCRIPTION
        Queries the Win32_Group CIM class with a filter of LocalAccount = True
        so that domain groups mirrored into the local SAM are excluded. Only
        groups that are native to the target machine are returned.

        When ComputerName resolves to the local machine (localhost, 127.0.0.1,
        or $env:COMPUTERNAME) no CIM ComputerName parameter is sent, avoiding
        an unnecessary remote-protocol hop.

    .PARAMETER ComputerName
        The hostname or IP address of the target computer.
        Defaults to "localhost" (the local machine).
        Accepts pipeline input.

    .OUTPUTS
        System.Management.Automation.PSCustomObject[]
        An array of selected Win32_Group objects with the following properties:
            Name, Caption, SID, Status
        Returns $null if the query fails.

    .EXAMPLE
        Get-ComputerLocalGroup
        Returns all local security groups on the local machine.

    .EXAMPLE
        Get-ComputerLocalGroup -ComputerName "WORKSTATION42"
        Returns all local security groups on WORKSTATION42.

    .EXAMPLE
        "SERVER01","SERVER02" | Get-ComputerLocalGroup
        Returns local security groups for each computer in the pipeline.
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
