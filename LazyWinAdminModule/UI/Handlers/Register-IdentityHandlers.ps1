# LazyWinAdmin UI section — Identity tab handlers (local accounts + Entra ID).
# Dot-sourced by Start-LazyWinAdmin INTO its scope.

# --- IDENTITY HANDLERS (LOCAL) ---
$btnGetLocalUsers.Add_Click({
    if (-not ($RequireComputerName.Invoke())) { return }
    $comp = $txtComputerName.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ComputerLocalUser.ps1'")) `
        -Parameters  @{ t = $comp } `
        -ScriptBlock { Get-ComputerLocalUser -ComputerName $t } `
        -OnCompleted {
            param($data)
            $lvLocalAccounts.Items.Clear()
            $data | ForEach-Object { $lvLocalAccounts.Items.Add($_) }
        }
})

$btnGetLocalGroups.Add_Click({
    if (-not ($RequireComputerName.Invoke())) { return }
    $comp = $txtComputerName.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ComputerLocalGroup.ps1'")) `
        -Parameters  @{ t = $comp } `
        -ScriptBlock { Get-ComputerLocalGroup -ComputerName $t } `
        -OnCompleted {
            param($data)
            $lvLocalAccounts.Items.Clear()
            $data | ForEach-Object { $lvLocalAccounts.Items.Add($_) }
        }
})

# --- IDENTITY HANDLERS (ENTRA) ---
$btnGetEntraUsers.Add_Click({
    if (-not ($RequireCloudSession.Invoke())) { return }
    $search = $txtEntraSearch.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-EntraIdentity.ps1'")) `
        -Parameters  @{ s = $search } `
        -ScriptBlock { Get-EntraIdentity -Type "User" -Search $s } `
        -OnCompleted {
            param($data)
            $lvEntraIdentity.Items.Clear()
            $data | ForEach-Object { $lvEntraIdentity.Items.Add($_) }
        }
})

$btnGetEntraGroups.Add_Click({
    if (-not ($RequireCloudSession.Invoke())) { return }
    $search = $txtEntraSearch.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-EntraIdentity.ps1'")) `
        -Parameters  @{ s = $search } `
        -ScriptBlock { Get-EntraIdentity -Type "Group" -Search $s } `
        -OnCompleted {
            param($data)
            $lvEntraIdentity.Items.Clear()
            $data | ForEach-Object {
                $item = $_
                if ($item.Description) { $item.UserPrincipalName = $item.Description }
                $lvEntraIdentity.Items.Add($item)
            }
        }
})
