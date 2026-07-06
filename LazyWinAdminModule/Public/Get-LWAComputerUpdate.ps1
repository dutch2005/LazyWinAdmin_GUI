function Get-LWAComputerUpdate {
    <#
    .SYNOPSIS
        Retrieves pending Windows Updates from a local or remote computer.
    .DESCRIPTION
        Uses Invoke-Command to execute a WUA query remotely to list pending updates.
    .EXAMPLE
        Get-LWAComputerUpdate -ComputerName 'Server01'
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string]$ComputerName = 'localhost'
    )

    try {
        $scriptBlock = {
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            
            # 0 means not installed
            $searchResult = $updateSearcher.Search("IsInstalled=0")
            
            $results = @()
            for ($i = 0; $i -lt $searchResult.Updates.Count; $i++) {
                $update = $searchResult.Updates.Item($i)
                $results += [PSCustomObject]@{
                    Title = $update.Title
                    KB = ($update.KBArticleIDs -join ', ')
                    IsDownloaded = $update.IsDownloaded
                }
            }
            return $results
        }

        if ($ComputerName -eq 'localhost') {
            Invoke-Command -ScriptBlock $scriptBlock -ErrorAction Stop
        } else {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock -ErrorAction Stop
        }
    }
    catch {
        Write-Verbose "Error fetching Windows updates from $($ComputerName): $_"
        throw $_
    }
}
