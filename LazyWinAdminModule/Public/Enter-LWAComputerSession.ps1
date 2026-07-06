function Enter-LWAComputerSession {
    <#
    .SYNOPSIS
        Opens an interactive remote PowerShell session to the target computer.
    .DESCRIPTION
        Launches a new PowerShell window executing Enter-PSSession for immediate CLI support.
    .EXAMPLE
        Enter-LWAComputerSession -ComputerName 'Server01'
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )

    try {
        if ($ComputerName -eq 'localhost') {
            throw "Cannot start interactive remote session to localhost."
        }

        # Start a new powershell process that immediately enters a PSSession and stays open
        $argList = "-NoExit -Command `"Enter-PSSession -ComputerName '$ComputerName'`""
        
        Start-Process pwsh -ArgumentList $argList -ErrorAction SilentlyContinue
        if (-not $?) {
            # Fallback to Windows PowerShell
            Start-Process powershell -ArgumentList $argList -ErrorAction Stop
        }
    }
    catch {
        Write-Verbose "Error starting remote session to $($ComputerName): $_"
        throw $_
    }
}
