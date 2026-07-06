function Stop-LWAComputerProcess {
    <#
    .SYNOPSIS
        Terminates a process on a local or remote computer.
    .DESCRIPTION
        Uses CIM sessions to invoke the Terminate method on Win32_Process instances.
    .EXAMPLE
        Stop-LWAComputerProcess -ComputerName 'Server01' -ProcessId 1234
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string]$ComputerName = 'localhost',

        [Parameter(Mandatory=$true)]
        [int]$ProcessId
    )

    try {
        $cimSession = Get-LocalOrRemoteCimSession -ComputerName $ComputerName

        $cimParams = @{}
        if ($cimSession) { $cimParams.CimSession = $cimSession }

        $process = Get-CimInstance @cimParams -ClassName Win32_Process -Filter "ProcessId = $ProcessId" -ErrorAction Stop

        if ($process) {
            if ($PSCmdlet.ShouldProcess("Process ID $ProcessId on $($ComputerName)", "Terminate")) {
                Invoke-CimMethod -InputObject $process -MethodName Terminate -ErrorAction Stop
                return $true
            }
        } else {
            Write-Warning "Process ID $ProcessId not found on $($ComputerName)."
            return $false
        }
    }
    catch {
        Write-Verbose "Error terminating process on $($ComputerName): $_"
        throw $_
    }
}
