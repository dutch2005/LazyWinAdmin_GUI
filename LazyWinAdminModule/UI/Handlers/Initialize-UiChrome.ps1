# LazyWinAdmin UI section — clipboard context menus + dispatcher/clock timers.
# Dot-sourced by Start-LazyWinAdmin INTO its scope, AFTER controls and helpers
# exist. This runs code at dot-source time (wires context menus, starts timers).

# --- CLIPBOARD CONTEXT MENUS ---
# Right-click any ListView row → "Copy Row to Clipboard" (tab-separated values).
# Uses PlacementTarget from the ContextMenu to avoid closure variable capture issues.
foreach ($lv in @($lvServices, $lvSoftware, $lvNetwork, $lvLocalAccounts,
                   $lvEntraIdentity, $lvAdResults, $lvIntuneDevices, $lvIntuneScripts,
                   $lvHwDisks, $lvComplianceStatus, $lvMailboxPerms, $lvAzureResources)) {
    $ctxMenu  = [System.Windows.Controls.ContextMenu]::new()
    $copyItem = [System.Windows.Controls.MenuItem]::new()
    $copyItem.Header = "Copy Row to Clipboard"
    $copyItem.Add_Click({
        $listView = $this.Parent.PlacementTarget
        if ($null -ne $listView.SelectedItem) {
            $values = $listView.SelectedItem.PSObject.Properties |
                      Where-Object { $_.MemberType -eq 'NoteProperty' } |
                      ForEach-Object { $_.Value }
            [System.Windows.Clipboard]::SetText(($values -join "`t"))
        }
    })
    $ctxMenu.Items.Add($copyItem) | Out-Null
    $lv.ContextMenu = $ctxMenu
}

# DispatcherTimer — drains the UI callback queue on the WPF thread every 50 ms.
# Background jobs enqueue their results via Register-ObjectEvent actions.
# The timer dequeues and calls OnCompleted callbacks here, on the UI thread,
# with full access to all WPF controls — no Dispatcher.Invoke needed in callbacks.
$uiTimer          = [System.Windows.Threading.DispatcherTimer]::new()
$uiTimer.Interval = [TimeSpan]::FromMilliseconds(50)
$uiTimer.Add_Tick({
    $workItem = $null
    while ($state.SyncHash.UIQueue.TryDequeue([ref]$workItem)) {
        try   { & $workItem.Callback $workItem.Result }
        catch { $AppendOutput.Invoke("[!] UI callback error: $_") }
        finally { $workItem.BusyFn.Invoke($false) }
    }
})
$uiTimer.Start()

# Clock timer — updates the status bar time display every second.
$clockTimer          = [System.Windows.Threading.DispatcherTimer]::new()
$clockTimer.Interval = [TimeSpan]::FromSeconds(1)
$clockTimer.Add_Tick({ $lblTime.Text = (Get-Date).ToString('HH:mm:ss') })
$clockTimer.Start()
