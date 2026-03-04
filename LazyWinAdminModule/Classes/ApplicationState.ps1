# Requires PowerShell 5.1+ (Ideally 7.4+)

class LazyWinAdminState {
    [hashtable] $SyncHash
    [System.Management.Automation.Runspaces.RunspacePool] $RunspacePool

    LazyWinAdminState() {
        $this.SyncHash = [hashtable]::Synchronized(@{})
        $this.SyncHash.Logs = [System.Collections.ArrayList]::new()
        $this.SyncHash.IsBusy = $false
        
        # Setup Runspace Pool for multithreading
        $this.RunspacePool = [runspacefactory]::CreateRunspacePool(1, 5)
        $this.RunspacePool.Open()
    }

    [void] Log([string]$Message) {
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $this.SyncHash.Logs.Add("[$timestamp] $Message")
    }

    [void] Dispose() {
        if ($this.RunspacePool) {
            $this.RunspacePool.Dispose()
        }
    }
}