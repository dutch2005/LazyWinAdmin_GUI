# LazyWinAdmin UI section — System & Service tab handlers.
# Dot-sourced by Start-LazyWinAdmin INTO its scope. Handler bodies are unchanged
# from the former monolith; they resolve controls, helpers, $PrivatePath and
# Invoke-AsyncAction from the enclosing scope exactly as before.

# --- SYSTEM HANDLERS ---
$btnPing.Add_Click({
    if (-not ($RequireComputerName.Invoke())) { return }
    $comp = $txtComputerName.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Test-ComputerPort.ps1'")) `
        -Parameters  @{ t = $comp } `
        -ScriptBlock {
            # Test WinRM port 5985 — ICMP ping alone does not confirm remote management
            # is available. This is the actual transport CIM uses.
            $result = Test-ComputerPort -ComputerName $t -Port 5985 -TimeoutMs 3000
            if ($result -eq 'Open') { "[OK] $t online (WinRM port 5985 reachable)" }
            else                    { "[!] $t — WinRM port 5985 not reachable ($result)" }
        } `
        -OnCompleted {
            param($res) $AppendOutput.Invoke($res)
        }
})

$btnUptime.Add_Click({
    if (-not ($RequireComputerName.Invoke())) { return }
    $comp = $txtComputerName.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ComputerUptime.ps1'")) `
        -Parameters  @{ t = $comp } `
        -ScriptBlock { Get-ComputerUptime -ComputerName $t } `
        -OnCompleted {
            param($res) $AppendOutput.Invoke("[UPTIME] $res")
        }
})

$btnEnableRdp.Add_Click({
    if (-not ($RequireComputerName.Invoke())) { return }
    $comp = $txtComputerName.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Set-ComputerRDP.ps1'")) `
        -Parameters  @{ t = $comp } `
        -ScriptBlock { Set-ComputerRDP -ComputerName $t -Enabled $true } `
        -OnCompleted {
            param($res)
            $AppendOutput.Invoke("[RDP] $res")
            if ($res -match '^Error:') { $AdminHint.Invoke($comp) }
        }
})

$btnDisableRdp.Add_Click({
    if (-not ($RequireComputerName.Invoke())) { return }
    $comp = $txtComputerName.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Set-ComputerRDP.ps1'")) `
        -Parameters  @{ t = $comp } `
        -ScriptBlock { Set-ComputerRDP -ComputerName $t -Enabled $false } `
        -OnCompleted {
            param($res)
            $AppendOutput.Invoke("[RDP] $res")
            if ($res -match '^Error:') { $AdminHint.Invoke($comp) }
        }
})

# --- SERVICE HANDLERS ---
$btnGetServices.Add_Click({
    if (-not ($RequireComputerName.Invoke())) { return }
    $comp   = $txtComputerName.Text
    $search = $txtServiceSearch.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ComputerService.ps1'")) `
        -Parameters  @{ t = $comp; s = $search } `
        -ScriptBlock { Get-ComputerService -ComputerName $t -Name $s } `
        -OnCompleted {
            param($data)
            $lvServices.Items.Clear()
            $data | ForEach-Object { $lvServices.Items.Add($_) }
            $lblServicesCount.Text = "$($lvServices.Items.Count) service(s)"
        }
})

$btnGetStoppedAuto.Add_Click({
    if (-not ($RequireComputerName.Invoke())) { return }
    $comp = $txtComputerName.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ComputerService.ps1'")) `
        -Parameters  @{ t = $comp } `
        -ScriptBlock { Get-ComputerService -ComputerName $t -OnlyAutoStopped } `
        -OnCompleted {
            param($data)
            $lvServices.Items.Clear()
            $data | ForEach-Object { $lvServices.Items.Add($_) }
            $lblServicesCount.Text = "$($lvServices.Items.Count) service(s)"
        }
})

$btnStartService.Add_Click({
    if (-not ($RequireComputerName.Invoke())) { return }
    $selected = $lvServices.SelectedItem
    if ($null -eq $selected) {
        $lblStatus.Text = "[!] Select a service from the list first."
        return
    }
    $comp    = $txtComputerName.Text
    $svcName = $selected.Name
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Invoke-ComputerServiceControl.ps1'")) `
        -Parameters  @{ computerName = $comp; serviceName = $svcName; action = 'Start' } `
        -ScriptBlock { Invoke-ComputerServiceControl -ComputerName $computerName -ServiceName $serviceName -Action $action } `
        -OnCompleted {
            param($res)
            $AppendOutput.Invoke("[Service] $res")
            $lblStatus.Text = $res
            if ($res -match '^Error:') { $AdminHint.Invoke($comp) }
        }
})

$btnStopService.Add_Click({
    if (-not ($RequireComputerName.Invoke())) { return }
    $selected = $lvServices.SelectedItem
    if ($null -eq $selected) {
        $lblStatus.Text = "[!] Select a service from the list first."
        return
    }
    $comp    = $txtComputerName.Text
    $svcName = $selected.Name
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Invoke-ComputerServiceControl.ps1'")) `
        -Parameters  @{ computerName = $comp; serviceName = $svcName; action = 'Stop' } `
        -ScriptBlock { Invoke-ComputerServiceControl -ComputerName $computerName -ServiceName $serviceName -Action $action } `
        -OnCompleted {
            param($res)
            $AppendOutput.Invoke("[Service] $res")
            $lblStatus.Text = $res
            if ($res -match '^Error:') { $AdminHint.Invoke($comp) }
        }
})

$btnRestartService.Add_Click({
    if (-not ($RequireComputerName.Invoke())) { return }
    $selected = $lvServices.SelectedItem
    if ($null -eq $selected) {
        $lblStatus.Text = "[!] Select a service from the list first."
        return
    }
    $comp    = $txtComputerName.Text
    $svcName = $selected.Name
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Invoke-ComputerServiceControl.ps1'")) `
        -Parameters  @{ computerName = $comp; serviceName = $svcName; action = 'Restart' } `
        -ScriptBlock { Invoke-ComputerServiceControl -ComputerName $computerName -ServiceName $serviceName -Action $action } `
        -OnCompleted {
            param($res)
            $AppendOutput.Invoke("[Service] $res")
            $lblStatus.Text = $res
            if ($res -match '^Error:') { $AdminHint.Invoke($comp) }
        }
})
