function Get-LWAComputerEventLog {
    <#
    .SYNOPSIS
        Retrieves critical application and system errors from a computer.
    .DESCRIPTION
        Uses Get-WinEvent to fetch recent error logs.
    .EXAMPLE
        Get-LWAComputerEventLog -ComputerName 'Server01' -Hours 24
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string]$ComputerName = 'localhost',

        [int]$Hours = 24
    )

    try {
        $startTime = (Get-Date).AddHours(-$Hours)
        
        $filter = @{
            LogName   = @('System', 'Application')
            Level     = 2 # Error
            StartTime = $startTime
        }

        if ($ComputerName -eq 'localhost') {
            Get-WinEvent -FilterHashtable $filter -ErrorAction Stop
        } else {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                param($f)
                Get-WinEvent -FilterHashtable $f -ErrorAction Stop
            } -ArgumentList $filter -ErrorAction Stop
        }
    }
    catch {
        Write-Verbose "Error fetching event logs from $($ComputerName): $_"
        throw $_
    }
}
