function Get-LWAComputerProcess {
    <#
    .SYNOPSIS
        Retrieves processes from a local or remote computer.
    .DESCRIPTION
        Uses CIM sessions to query Win32_Process instances.
    .EXAMPLE
        Get-LWAComputerProcess -ComputerName 'Server01' -Name 'chrome'
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string]$ComputerName = 'localhost',

        [string]$Name
    )

    try {
        $cimSession = Get-LocalOrRemoteCimSession -ComputerName $ComputerName

        $cimParams = @{}
        if ($cimSession) { $cimParams.CimSession = $cimSession }

        $filter = ""
        if ($Name) {
            $filter = "Name LIKE '%$Name%'"
        }

        if ($filter) {
            Get-CimInstance @cimParams -ClassName Win32_Process -Filter $filter -ErrorAction Stop
        } else {
            Get-CimInstance @cimParams -ClassName Win32_Process -ErrorAction Stop
        }
    }
    catch {
        Write-Verbose "Error fetching processes from $($ComputerName): $_"
        throw $_
    }
}
