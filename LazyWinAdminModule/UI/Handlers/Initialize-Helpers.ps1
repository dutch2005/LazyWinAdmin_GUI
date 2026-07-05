# LazyWinAdmin UI section — shared helpers + async engine.
# Dot-sourced by Start-LazyWinAdmin INTO its scope. Requires $window, $state,
# $pbBusy, $lblStatus, $txtOutput, $txtComputerName, $isAdmin (defined earlier).
# The helper scriptblocks and Invoke-AsyncAction close over that scope, so they
# behave identically to the former monolithic function.

# --- UI HELPERS ---
# CheckAccess() returns $true when already on the UI thread — execute directly.
# From a background / event thread it returns $false — marshal via Dispatcher.Invoke.
# Skipping the Invoke when already on the UI thread prevents re-entrant
# DispatcherFrame pushes that cause the application to freeze.
$AppendOutput = {
    param($text)
    if ($window.Dispatcher.CheckAccess()) {
        $txtOutput.AppendText("$text`n")
        $txtOutput.ScrollToEnd()
    } else {
        $window.Dispatcher.Invoke([action]{
            $txtOutput.AppendText("$text`n")
            $txtOutput.ScrollToEnd()
        })
    }
}

$SetBusy = {
    param([bool]$isBusy)
    # Track busy state in SyncHash so event-thread code can read it without touching UI
    $state.SyncHash.IsBusy = $isBusy
    if ($window.Dispatcher.CheckAccess()) {
        $pbBusy.IsIndeterminate = $isBusy
        $lblStatus.Text = if ($isBusy) { "Working..." } else { "Ready" }
    } else {
        $window.Dispatcher.Invoke([action]{
            $pbBusy.IsIndeterminate = $isBusy
            $lblStatus.Text = if ($isBusy) { "Working..." } else { "Ready" }
        })
    }
}

# --- PRE-FLIGHT GUARDS ---
# These run synchronously on the UI thread before any async dispatch.
# Return $false to abort the action; the handler should 'return' immediately.

# Checks that the user has successfully authenticated against Entra ID / Azure.
# Must be called before any button handler that invokes a CLOUD-layer function.
$RequireCloudSession = {
    if (-not $state.SyncHash.CloudConnected) {
        $lblStatus.Text = "[!] Cloud authentication required — connect on the Cloud tab first."
        $AppendOutput.Invoke("[!] Action blocked: not authenticated. Use the Cloud tab to connect to Entra ID / Azure first.")
        return $false
    }
    return $true
}

# Checks that a non-empty computer name has been entered.
# Must be called before any button handler that opens a CIM session.
$RequireComputerName = {
    if ([string]::IsNullOrWhiteSpace($txtComputerName.Text)) {
        $lblStatus.Text = "[!] No computer name — enter a target in the Computer Name field."
        $AppendOutput.Invoke("[!] Action blocked: enter a Computer Name before running this action.")
        return $false
    }
    return $true
}

# Checks that Exchange Online is connected.
# Must be called before any button handler that calls Exchange cmdlets.
$RequireExchangeSession = {
    if (-not $state.SyncHash.ExchangeConnected) {
        $lblStatus.Text = "[!] Exchange not connected — use the Exchange › Connection tab first."
        return $false
    }
    return $true
}

# Appends an admin-rights hint to the output box when all three are true:
#   1. The operation returned no results (null/empty data)
#   2. The process is not elevated
#   3. The target is the local machine (localhost / 127.0.0.1 / $env:COMPUTERNAME)
# Called from OnCompleted handlers for features that require local admin.
$AdminHint = {
    param([string]$computer)
    $isLocalTarget = ($computer -ieq 'localhost'   -or
                      $computer -ieq '127.0.0.1'   -or
                      $computer -ieq $env:COMPUTERNAME)
    if (-not $isAdmin -and $isLocalTarget) {
        $AppendOutput.Invoke(
            "[!] No results returned. This feature requires local Administrator rights." +
            " Use the 'Restart as Admin' button in the status bar to relaunch elevated."
        )
    }
}

# --- EXPORT CSV HELPER ---
# Opens a SaveFileDialog and writes all ListView items to a UTF-8 CSV file.
# Runs synchronously on the UI thread — no async needed (file dialog is modal).
$ExportListViewToCsv = {
    param([System.Windows.Controls.ListView]$lv, [string]$defaultName)
    if ($lv.Items.Count -eq 0) {
        $lblStatus.Text = "[!] No data to export — run a query first."
        return
    }
    $dialog            = [Microsoft.Win32.SaveFileDialog]::new()
    $dialog.Filter     = "CSV Files (*.csv)|*.csv"
    $dialog.FileName   = $defaultName
    $dialog.DefaultExt = ".csv"
    if ($dialog.ShowDialog() -eq $true) {
        try {
            $lv.Items | Export-Csv -Path $dialog.FileName -NoTypeInformation -Encoding UTF8 -Force
            $lblStatus.Text = "Exported $($lv.Items.Count) row(s) to $($dialog.FileName)"
            $AppendOutput.Invoke("[Export] Saved $($lv.Items.Count) row(s) to $($dialog.FileName)")
        }
        catch {
            $lblStatus.Text = "[!] Export failed: $($_.Exception.Message)"
        }
    }
}

# --- ASYNC HELPER ---
# Critical changes from previous version:
#
#   1. REMOVED: Get-Content + Invoke-Expression pattern.
#      Private functions are now loaded into the thread job runspace via -InitializationScript,
#      which dot-sources the file at the known path. The file path is embedded at call-site
#      construction time (never from user input), eliminating the code-injection vector.
#
#   2. REMOVED: Watcher job (Start-ThreadJob wrapping Wait-Job).
#      Replaced with Register-ObjectEvent on the job's StateChanged event.
#      The event fires on the PowerShell event thread — zero watcher threads.
#      Dispatcher.Invoke marshals UI updates back to the WPF thread correctly.
#
#   3. RENAMED: param($p, $s) -> param($__p__, $__action__).
#      The original names collided with caller-supplied parameter keys
#      (e.g. key 's' for search) unpacked by Set-Variable, overwriting $s
#      before & $s could invoke the scriptblock.
function Invoke-AsyncAction {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseUsingScopeModifierInNewRunspaces', '',
        Justification = '$__p__ and $__action__ are param() in the ScriptBlock; $key is a foreach variable — all declared within the block')]
    param(
        [scriptblock]$ScriptBlock,
        [hashtable]$Parameters             = @{},
        [scriptblock]$OnCompleted,
        [scriptblock]$InitializationScript = {}
    )

    $SetBusy.Invoke($true)

    try {
        $job = Start-ThreadJob `
                   -InitializationScript $InitializationScript `
                   -ArgumentList $Parameters, $ScriptBlock -ScriptBlock {
            param($__p__, $__action__)
            foreach ($key in $__p__.Keys) { Set-Variable -Name $key -Value $__p__[$key] }
            & $__action__
        }
    }
    catch {
        # Runs on UI thread — update directly, no Dispatcher.Invoke needed.
        $lblStatus.Text         = "[!] Could not start background job: $_"
        $pbBusy.IsIndeterminate = $false
        $state.SyncHash.IsBusy  = $false
        return
    }

    # When the job finishes, enqueue the result for the DispatcherTimer to process
    # on the WPF UI thread.  This avoids Dispatcher.Invoke/InvokeAsync entirely,
    # eliminating all re-entrant DispatcherFrame and cross-thread closure issues.
    Register-ObjectEvent -InputObject $job -EventName StateChanged -MessageData @{
        Job      = $job
        Queue    = $state.SyncHash.UIQueue
        Callback = $OnCompleted
        BusyFn   = $SetBusy
    } -Action {
        $jobState = $Event.SourceArgs[0].JobStateInfo.State
        if ($jobState -notin 'Completed', 'Failed', 'Stopped') { return }

        $res    = Receive-Job -Job $Event.MessageData.Job -ErrorAction SilentlyContinue
        $evtSrc = $EventSubscriber.SourceIdentifier
        $evtJob = $Event.MessageData.Job

        $Event.MessageData.Queue.Enqueue([PSCustomObject]@{
            Callback = $Event.MessageData.Callback
            Result   = $res
            BusyFn   = $Event.MessageData.BusyFn
        })

        Unregister-Event -SourceIdentifier $evtSrc -ErrorAction SilentlyContinue
        Remove-Job       -Job $evtJob -Force        -ErrorAction SilentlyContinue
    } | Out-Null
}
