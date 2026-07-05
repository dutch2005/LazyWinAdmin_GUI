# LazyWinAdmin UI section — Registry + Active Directory tab handlers.
# Dot-sourced by Start-LazyWinAdmin INTO its scope.

# --- REGISTRY HANDLERS ---
$btnRegRead.Add_Click({
    if (-not ($RequireComputerName.Invoke())) { return }
    $comp = $txtComputerName.Text
    $hive = $cbRegHive.Text
    $path = $txtRegPath.Text
    $val  = $txtRegValueName.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Invoke-ComputerRegistry.ps1'")) `
        -Parameters  @{ t = $comp; h = $hive; p = $path; v = $val } `
        -ScriptBlock { Invoke-ComputerRegistry -Action "Get" -ComputerName $t -Hive $h -KeyPath $p -ValueName $v } `
        -OnCompleted {
            param($res)
            $txtRegResult.Text = if ($null -ne $res) { "Value: $res" } else { "Value not found or error." }
        }
})

$btnRegWrite.Add_Click({
    if (-not ($RequireComputerName.Invoke())) { return }
    $comp = $txtComputerName.Text
    $hive = $cbRegHive.Text
    $path = $txtRegPath.Text
    $val  = $txtRegValueName.Text
    $data = $txtRegValueData.Text
    $type = $cbRegType.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Invoke-ComputerRegistry.ps1'")) `
        -Parameters  @{ t = $comp; h = $hive; p = $path; v = $val; d = $data; ty = $type } `
        -ScriptBlock { Invoke-ComputerRegistry -Action "Set" -ComputerName $t -Hive $h -KeyPath $p -ValueName $v -Value $d -ValueType $ty } `
        -OnCompleted {
            param($res)
            if ($res) {
                $txtRegResult.Text = "Success: Value written."
            }
            else {
                $txtRegResult.Text = "Error: Failed to write value."
                $AdminHint.Invoke($comp)
            }
        }
})

$btnRegDelete.Add_Click({
    if (-not ($RequireComputerName.Invoke())) { return }
    $comp = $txtComputerName.Text
    $hive = $cbRegHive.Text
    $path = $txtRegPath.Text
    $val  = $txtRegValueName.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Invoke-ComputerRegistry.ps1'")) `
        -Parameters  @{ t = $comp; h = $hive; p = $path; v = $val } `
        -ScriptBlock { Invoke-ComputerRegistry -Action "Remove" -ComputerName $t -Hive $h -KeyPath $p -ValueName $v } `
        -OnCompleted {
            param($res)
            if ($res) {
                $txtRegResult.Text = "Success: Item removed."
            }
            else {
                $txtRegResult.Text = "Error: Failed to remove item."
                $AdminHint.Invoke($comp)
            }
        }
})

# --- ACTIVE DIRECTORY HANDLERS ---
# Requires RSAT (rsat-ad-ds) on the machine running LazyWinAdmin.
# AdFilter is the canonical search term — single-letter variables are forbidden by VOCABULARY.
$btnGetAdComputer.Add_Click({
    $comp     = $txtComputerName.Text
    $adFilter = $txtAdSearch.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ComputerADInfo.ps1'")) `
        -Parameters  @{ t = $comp; af = $adFilter } `
        -ScriptBlock { Get-ComputerADInfo -Type "Computer" -ComputerName $t -AdFilter $af } `
        -OnCompleted {
            param($data)
            $lvAdResults.Items.Clear()
            $data | ForEach-Object { $lvAdResults.Items.Add($_) }
        }
})

$btnGetAdUsers.Add_Click({
    $adFilter = $txtAdSearch.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ComputerADInfo.ps1'")) `
        -Parameters  @{ af = $adFilter } `
        -ScriptBlock { Get-ComputerADInfo -Type "User" -AdFilter $af } `
        -OnCompleted {
            param($data)
            $lvAdResults.Items.Clear()
            $data | ForEach-Object { $lvAdResults.Items.Add($_) }
        }
})

$btnGetAdGroups.Add_Click({
    $adFilter = $txtAdSearch.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ComputerADInfo.ps1'")) `
        -Parameters  @{ af = $adFilter } `
        -ScriptBlock { Get-ComputerADInfo -Type "Group" -AdFilter $af } `
        -OnCompleted {
            param($data)
            $lvAdResults.Items.Clear()
            $data | ForEach-Object { $lvAdResults.Items.Add($_) }
        }
})
