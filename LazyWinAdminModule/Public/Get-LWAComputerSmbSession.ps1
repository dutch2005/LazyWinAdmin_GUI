function Get-LWAComputerSmbSession {
    <#
    .SYNOPSIS
        Retrieves active SMB sessions from a local or remote computer.
    .DESCRIPTION
        Uses CIM sessions to query MSFT_SmbSession instances.
    .EXAMPLE
        Get-LWAComputerSmbSession -ComputerName 'Server01'
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

        Get-CimInstance @cimParams -Namespace Root\Microsoft\Windows\SMB -ClassName MSFT_SmbSession -ErrorAction Stop
    }
    catch {
        Write-Verbose "Error fetching SMB sessions from $($ComputerName): $_"
        throw $_
    }
}
