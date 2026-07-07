function Install-LWAComputerUpdate {
    <#
    .SYNOPSIS
        Forces a remote computer to search for, download, and install missing Windows Updates.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )
    process {
        $sb = {
            $session = New-Object -ComObject Microsoft.Update.Session
            $searcher = $session.CreateUpdateSearcher()
            $searchResult = $searcher.Search("IsInstalled=0 and Type='Software' and IsHidden=0")
            
            if ($searchResult.Updates.Count -eq 0) { return "No missing updates found." }
            
            $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
            foreach ($update in $searchResult.Updates) {
                if ($update.EulaAccepted -eq $false) { $update.AcceptEula() }
                $updatesToInstall.Add($update) | Out-Null
            }
            
            $downloader = $session.CreateUpdateDownloader()
            $downloader.Updates = $updatesToInstall
            $downloader.Download()
            
            $installer = $session.CreateUpdateInstaller()
            $installer.Updates = $updatesToInstall
            $installResult = $installer.Install()
            
            return "Installed $($updatesToInstall.Count) updates. Reboot Required: $($installResult.RebootRequired)"
        }
        
        $res = Invoke-Command -ComputerName $ComputerName -ScriptBlock $sb -ErrorAction Stop
        return "[OK] Windows Update triggered on $ComputerName. Result: $res"
    }
}
