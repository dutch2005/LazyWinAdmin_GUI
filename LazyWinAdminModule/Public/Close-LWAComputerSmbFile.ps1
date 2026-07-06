function Close-LWAComputerSmbFile {
    <#
    .SYNOPSIS
        Closes an open SMB file on a local or remote computer.
    .DESCRIPTION
        Uses CIM sessions to invoke the Close method on MSFT_SmbOpenFile instances.
    .EXAMPLE
        Close-LWAComputerSmbFile -ComputerName 'Server01' -FileId 12345
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string]$ComputerName = 'localhost',

        [Parameter(Mandatory=$true)]
        [uint64]$FileId
    )

    try {
        $cimSession = Get-LocalOrRemoteCimSession -ComputerName $ComputerName

        $cimParams = @{}
        if ($cimSession) { $cimParams.CimSession = $cimSession }

        $file = Get-CimInstance @cimParams -Namespace Root\Microsoft\Windows\SMB -ClassName MSFT_SmbOpenFile -Filter "FileId = $FileId" -ErrorAction Stop

        if ($file) {
            if ($PSCmdlet.ShouldProcess("SMB File ID $FileId on $($ComputerName)", "Close File")) {
                Invoke-CimMethod -InputObject $file -MethodName ForceClose -ErrorAction Stop
                return $true
            }
        } else {
            Write-Warning "SMB File ID $FileId not found on $($ComputerName)."
            return $false
        }
    }
    catch {
        Write-Verbose "Error closing SMB file on $($ComputerName): $_"
        throw $_
    }
}
