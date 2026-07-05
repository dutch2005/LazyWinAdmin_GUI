# LazyWinAdmin UI section — Export-to-CSV button handlers.
# Dot-sourced by Start-LazyWinAdmin INTO its scope. Uses the $ExportListViewToCsv
# helper defined in Initialize-Helpers.ps1.

$btnExportServices.Add_Click({
    $ExportListViewToCsv.Invoke($lvServices, "services_$($txtComputerName.Text)_$(Get-Date -Format yyyyMMdd).csv")
})
$btnExportSoftware.Add_Click({
    $ExportListViewToCsv.Invoke($lvSoftware, "software_$($txtComputerName.Text)_$(Get-Date -Format yyyyMMdd).csv")
})
$btnExportNetwork.Add_Click({
    $ExportListViewToCsv.Invoke($lvNetwork, "network_$($txtComputerName.Text)_$(Get-Date -Format yyyyMMdd).csv")
})
$btnExportIntuneDevices.Add_Click({
    $ExportListViewToCsv.Invoke($lvIntuneDevices, "intune_devices_$(Get-Date -Format yyyyMMdd).csv")
})
$btnExportMailboxPerms.Add_Click({
    $ExportListViewToCsv.Invoke($lvMailboxPerms, "mailbox_perms_$(Get-Date -Format yyyyMMdd).csv")
})
