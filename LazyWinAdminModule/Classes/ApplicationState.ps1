# Requires PowerShell 7.4+

class LazyWinAdminState {
    [hashtable] $SyncHash
    [System.Management.Automation.Runspaces.RunspacePool] $RunspacePool

    # Thread-safe CIM session cache — keyed by ComputerName.
    # Private functions open one session per call and close it in finally.
    # This cache is available for future cross-call reuse without rebuilding
    # the WSMan connection on every button click.
    # Adheres to: cim_session.* ALWAYS reuse-before-create (CONTRACTS)
    [hashtable] $CimSessions

    LazyWinAdminState() {
        $this.SyncHash = [hashtable]::Synchronized(@{})
        $this.SyncHash.Logs             = [System.Collections.ArrayList]::new()
        $this.SyncHash.IsBusy           = $false
        # Set to $true by the cloud-auth OnCompleted handler once [OK] is returned.
        # Read by $RequireCloudSession guard in button handlers before dispatching async work.
        $this.SyncHash.CloudConnected   = $false
        # Set to $true by the Exchange OnCompleted handler after a successful connection.
        # Read by $RequireExchangeSession guard.
        $this.SyncHash.ExchangeConnected = $false
        # Thread-safe queue drained by the DispatcherTimer on the WPF UI thread.
        # Register-ObjectEvent actions enqueue completed job results here instead of
        # calling Dispatcher.InvokeAsync, avoiding all cross-thread delegate issues.
        $this.SyncHash.UIQueue          = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()

        $this.CimSessions = [hashtable]::Synchronized(@{})

        # Runspace pool used by Start-ThreadJob for all async UI operations.
        # Min 1, max 5 concurrent thread jobs.
        $this.RunspacePool = [runspacefactory]::CreateRunspacePool(1, 5)
        $this.RunspacePool.Open()
    }

    [void] Log([string]$Message) {
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $this.SyncHash.Logs.Add("[$timestamp] $Message") | Out-Null
    }

    # Evict a stale or failed CIM session from the cache by ComputerName.
    [void] EvictCimSession([string]$ComputerName) {
        if ($this.CimSessions.ContainsKey($ComputerName)) {
            try {
                Remove-CimSession -CimSession $this.CimSessions[$ComputerName] -ErrorAction SilentlyContinue
            }
            catch { }
            $this.CimSessions.Remove($ComputerName)
        }
    }

    [void] Dispose() {
        # Close all cached CIM sessions before tearing down
        foreach ($cs in $this.CimSessions.Values) {
            try { Remove-CimSession -CimSession $cs -ErrorAction SilentlyContinue } catch { }
        }
        $this.CimSessions.Clear()

        if ($this.RunspacePool) {
            $this.RunspacePool.Close()
            $this.RunspacePool.Dispose()
        }
    }
}
