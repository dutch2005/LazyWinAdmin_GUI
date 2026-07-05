# LazyWinAdmin UI section — Software / Hardware / Network tab handlers.
# Dot-sourced by Start-LazyWinAdmin INTO its scope.

# --- SOFTWARE HANDLERS ---
$btnGetSoftware.Add_Click({
    if (-not ($RequireComputerName.Invoke())) { return }
    $comp   = $txtComputerName.Text
    $search = $txtSoftwareSearch.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ComputerSoftware.ps1'")) `
        -Parameters  @{ t = $comp; s = $search } `
        -ScriptBlock { Get-ComputerSoftware -ComputerName $t -Search $s } `
        -OnCompleted {
            param($data)
            $lvSoftware.Items.Clear()
            $data | ForEach-Object { $lvSoftware.Items.Add($_) }
            $lblSoftwareCount.Text = "$($lvSoftware.Items.Count) application(s)"
        }
})

# --- HARDWARE HANDLERS ---
$btnGetHardware.Add_Click({
    if (-not ($RequireComputerName.Invoke())) { return }
    $comp         = $txtComputerName.Text
    $hwInitScript = [scriptblock]::Create(
        ". '$PrivatePath\Get-ComputerHardware.ps1'; . '$PrivatePath\Get-ComputerMotherboard.ps1'"
    )
    Invoke-AsyncAction `
        -InitializationScript $hwInitScript `
        -Parameters  @{ t = $comp } `
        -ScriptBlock {
            $hw   = Get-ComputerHardware   -ComputerName $t
            $mobo = Get-ComputerMotherboard -ComputerName $t
            return @{ hw = $hw; mobo = $mobo }
        } `
        -OnCompleted {
            param($data)
            if ($data.hw) {
                $hw = $data.hw
                $txtHwModel.Text  = "$($hw.Manufacturer) $($hw.Model)"
                $txtHwSerial.Text = $hw.SerialNumber
                $txtHwCpu.Text    = $hw.CPU
                $txtHwRam.Text    = "$($hw.RAM_GB) GB"
                $txtHwOs.Text     = $hw.OS
                $lvHwDisks.Items.Clear()
                $hw.Disks | ForEach-Object { $lvHwDisks.Items.Add($_) }
            }
            else {
                $AdminHint.Invoke($comp)
            }
            if ($data.mobo) {
                $txtHwMobo.Text = "$($data.mobo.Product) ($($data.mobo.SerialNumber))"
            }
        }
})

# --- NETWORK HANDLERS ---
$btnGetNetwork.Add_Click({
    if (-not ($RequireComputerName.Invoke())) { return }
    $comp   = $txtComputerName.Text
    $onlyIP = $chkOnlyIPEnabled.IsChecked
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ComputerNetwork.ps1'")) `
        -Parameters  @{ t = $comp; o = $onlyIP } `
        -ScriptBlock { Get-ComputerNetwork -ComputerName $t -OnlyIPEnabled $o } `
        -OnCompleted {
            param($data)
            $lvNetwork.Items.Clear()
            $data | ForEach-Object { $lvNetwork.Items.Add($_) }
            $lblNetworkCount.Text = "$($lvNetwork.Items.Count) adapter(s)"
        }
})
