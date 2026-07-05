# LazyWinAdmin UI section — Governance & Compliance handlers
# (Intune devices, Azure Resource Graph, Intune scripts, Device Compliance).
# Dot-sourced by Start-LazyWinAdmin INTO its scope.

# --- GOVERNANCE HANDLERS ---
$btnGetIntuneDevices.Add_Click({
    if (-not ($RequireCloudSession.Invoke())) { return }
    $search = $txtIntuneSearch.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-IntuneDevice.ps1'")) `
        -Parameters  @{ s = $search } `
        -ScriptBlock { Get-IntuneDevice -Search $s } `
        -OnCompleted {
            param($data)
            $lvIntuneDevices.Items.Clear()
            $data | ForEach-Object { $lvIntuneDevices.Items.Add($_) }
            $lblIntuneDevicesCount.Text = "$($lvIntuneDevices.Items.Count) device(s)"
        }
})

$btnGetAzureSummary.Add_Click({
    if (-not ($RequireCloudSession.Invoke())) { return }
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-AzureResourceSummary.ps1'")) `
        -ScriptBlock { Get-AzureResourceSummary } `
        -OnCompleted {
            param($data)
            $lvAzureResources.Items.Clear()
            $data | ForEach-Object { $lvAzureResources.Items.Add($_) }
        }
})

# --- INTUNE SCRIPTS HANDLERS ---
$btnGetIntuneScripts.Add_Click({
    if (-not ($RequireCloudSession.Invoke())) { return }
    $search = $txtIntuneScriptSearch.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-IntuneManagementScript.ps1'")) `
        -Parameters  @{ s = $search } `
        -ScriptBlock { Get-IntuneManagementScript -Search $s } `
        -OnCompleted {
            param($data)
            $lvIntuneScripts.Items.Clear()
            if ($data) {
                $data | ForEach-Object { $lvIntuneScripts.Items.Add($_) }
                $AppendOutput.Invoke("[Intune Scripts] $($data.Count) script(s) listed.")
            } else {
                $AppendOutput.Invoke("[Intune Scripts] No scripts found or not connected to Graph.")
            }
        }
})

$btnDownloadIntuneScripts.Add_Click({
    if (-not ($RequireCloudSession.Invoke())) { return }
    $search       = $txtIntuneScriptSearch.Text
    $downloadPath = $txtIntuneScriptDownloadPath.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-IntuneManagementScript.ps1'")) `
        -Parameters  @{ s = $search; dp = $downloadPath } `
        -ScriptBlock { Get-IntuneManagementScript -Search $s -DownloadPath $dp } `
        -OnCompleted {
            param($data)
            $lvIntuneScripts.Items.Clear()
            if ($data) {
                $data | ForEach-Object { $lvIntuneScripts.Items.Add($_) }
                $AppendOutput.Invoke("[Intune Scripts] $($data.Count) script(s) downloaded to $downloadPath.")
            } else {
                $AppendOutput.Invoke("[Intune Scripts] No scripts found or not connected to Graph.")
            }
        }
})

# --- DEVICE COMPLIANCE HANDLERS ---
$btnCheckCompliance.Add_Click({
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-DeviceComplianceStatus.ps1'")) `
        -ScriptBlock { Get-DeviceComplianceStatus } `
        -OnCompleted {
            param($data)
            $lvComplianceStatus.Items.Clear()
            $data | ForEach-Object { $lvComplianceStatus.Items.Add($_) }
        }
})

$btnFixLocation.Add_Click({
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Set-DeviceComplianceItem.ps1'")) `
        -ScriptBlock { Set-DeviceComplianceItem -Item 'LocationServices' } `
        -OnCompleted {
            param($res)
            $txtComplianceOutput.Text = $res
            if ($res -match '^Error:') { $AdminHint.Invoke($env:COMPUTERNAME) }
        }
})

$btnFixOutlookImages.Add_Click({
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Set-DeviceComplianceItem.ps1'")) `
        -ScriptBlock { Set-DeviceComplianceItem -Item 'OutlookExternalImages' } `
        -OnCompleted {
            param($res)
            $txtComplianceOutput.Text = $res
        }
})

$btnRemoveOneDrive.Add_Click({
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Set-DeviceComplianceItem.ps1'")) `
        -ScriptBlock { Set-DeviceComplianceItem -Item 'RemoveOneDrive' } `
        -OnCompleted {
            param($res)
            $txtComplianceOutput.Text = $res
            if ($res -match '^Error:') { $AdminHint.Invoke($env:COMPUTERNAME) }
        }
})

$btnFixUpdateHours.Add_Click({
    $startHour = 0
    $endHour   = 0
    if (-not [int]::TryParse($txtUpdateHoursStart.Text, [ref]$startHour) -or
        -not [int]::TryParse($txtUpdateHoursEnd.Text,   [ref]$endHour)   -or
        $startHour -lt 0 -or $startHour -gt 23 -or
        $endHour   -lt 0 -or $endHour   -gt 23) {
        $txtComplianceOutput.Text = "[!] Start and End hours must be integers between 0 and 23."
        return
    }
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Set-DeviceComplianceItem.ps1'")) `
        -Parameters  @{ sh = $startHour; eh = $endHour } `
        -ScriptBlock { Set-DeviceComplianceItem -Item 'WindowsUpdateActiveHours' -ActiveHoursStart $sh -ActiveHoursEnd $eh } `
        -OnCompleted {
            param($res)
            $txtComplianceOutput.Text = $res
            if ($res -match '^Error:') { $AdminHint.Invoke($env:COMPUTERNAME) }
        }
})
