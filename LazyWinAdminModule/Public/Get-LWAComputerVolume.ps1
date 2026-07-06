function Get-LWAComputerVolume {
    <#
    .SYNOPSIS
        Retrieves disk volume information from a local or remote computer.
    .DESCRIPTION
        Uses CIM sessions to query MSFT_Volume instances from the Root\Microsoft\Windows\Storage namespace.
    .EXAMPLE
        Get-LWAComputerVolume -ComputerName 'Server01'
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string]$ComputerName = 'localhost'
    )

    try {
        $cimSession = Get-LocalOrRemoteCimSession -ComputerName $ComputerName

        $cimParams = @{}
        if ($cimSession) { $cimParams.CimSession = $cimSession }

        # Standard MSFT_Volume
        Get-CimInstance @cimParams -Namespace Root\Microsoft\Windows\Storage -ClassName MSFT_Volume -ErrorAction Stop
    }
    catch {
        Write-Verbose "Error fetching volumes from $($ComputerName): $_"
        throw $_
    }
}
