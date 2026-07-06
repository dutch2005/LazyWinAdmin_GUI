# LazyWinAdmin UI section - RMM & PIM handlers.
# Dot-sourced by Start-LazyWinAdmin INTO its scope.

# --- ON-PREMISE RMM HANDLERS ---

$btnRmmProcess.Add_Click({
    $comp = $txtRmmComputer.Text
    if ([string]::IsNullOrWhiteSpace($comp)) { return }
    $txtRmmOutput.Text = "Fetching processes for $comp..."
    
    Invoke-AsyncAction `
        -Parameters @{ c = $comp } `
        -ScriptBlock { Get-LWAComputerProcess -ComputerName $c } `
        -OnCompleted {
            param($res)
            $txtRmmOutput.Text = ($res | Format-Table -AutoSize | Out-String)
        }
})

$btnRmmEventLog.Add_Click({
    $comp = $txtRmmComputer.Text
    if ([string]::IsNullOrWhiteSpace($comp)) { return }
    $txtRmmOutput.Text = "Fetching event logs for $comp..."
    
    Invoke-AsyncAction `
        -Parameters @{ c = $comp } `
        -ScriptBlock { Get-LWAComputerEventLog -ComputerName $c } `
        -OnCompleted {
            param($res)
            $txtRmmOutput.Text = ($res | Format-Table -AutoSize | Out-String)
        }
})

$btnRmmVolume.Add_Click({
    $comp = $txtRmmComputer.Text
    if ([string]::IsNullOrWhiteSpace($comp)) { return }
    $txtRmmOutput.Text = "Fetching volumes for $comp..."
    
    Invoke-AsyncAction `
        -Parameters @{ c = $comp } `
        -ScriptBlock { Get-LWAComputerVolume -ComputerName $c } `
        -OnCompleted {
            param($res)
            $txtRmmOutput.Text = ($res | Format-Table -AutoSize | Out-String)
        }
})

$btnRmmSmb.Add_Click({
    $comp = $txtRmmComputer.Text
    if ([string]::IsNullOrWhiteSpace($comp)) { return }
    $txtRmmOutput.Text = "Fetching SMB sessions for $comp..."
    
    Invoke-AsyncAction `
        -Parameters @{ c = $comp } `
        -ScriptBlock { Get-LWAComputerSmbSession -ComputerName $c } `
        -OnCompleted {
            param($res)
            $txtRmmOutput.Text = ($res | Format-Table -AutoSize | Out-String)
        }
})

$btnRmmUpdates.Add_Click({
    $comp = $txtRmmComputer.Text
    if ([string]::IsNullOrWhiteSpace($comp)) { return }
    $txtRmmOutput.Text = "Fetching pending Windows Updates for $comp..."
    
    Invoke-AsyncAction `
        -Parameters @{ c = $comp } `
        -ScriptBlock { Get-LWAComputerUpdate -ComputerName $c } `
        -OnCompleted {
            param($res)
            $txtRmmOutput.Text = ($res | Format-Table -AutoSize | Out-String)
        }
})

$btnRmmSession.Add_Click({
    $comp = $txtRmmComputer.Text
    if ([string]::IsNullOrWhiteSpace($comp)) { return }
    Enter-LWAComputerSession -ComputerName $comp
    $txtRmmOutput.Text = "Launched interactive PSRemoting session for $comp in a new window."
})


# --- CLOUD PIM HANDLERS ---

$btnRmmBitLocker.Add_Click({
    $target = $txtRmmCloudTarget.Text
    $ticket = $txtRmmTicket.Text
    if ([string]::IsNullOrWhiteSpace($target)) { return }
    
    $txtRmmOutput.Text = "Fetching BitLocker key for device '$target' using Justification '$ticket' (Will auto-elevate PIM if needed)..."
    
    Invoke-AsyncAction `
        -Parameters @{ t = $target; j = $ticket } `
        -ScriptBlock { Get-LWABitLockerKey -DeviceId $t -Justification $j } `
        -OnCompleted {
            param($res)
            $txtRmmOutput.Text = ($res | Format-List | Out-String)
        }
})

$btnRmmIntuneSync.Add_Click({
    $target = $txtRmmCloudTarget.Text
    $ticket = $txtRmmTicket.Text
    if ([string]::IsNullOrWhiteSpace($target)) { return }
    
    $txtRmmOutput.Text = "Triggering Intune Sync for device '$target' using Justification '$ticket'..."
    
    Invoke-AsyncAction `
        -Parameters @{ t = $target; j = $ticket } `
        -ScriptBlock { Invoke-LWAIntuneAction -DeviceId $t -Action "Sync" -Justification $j } `
        -OnCompleted {
            param($res)
            $txtRmmOutput.Text = "Intune Sync initiated successfully."
        }
})

$btnRmmEntraLogs.Add_Click({
    $target = $txtRmmCloudTarget.Text
    $ticket = $txtRmmTicket.Text
    
    $txtRmmOutput.Text = "Fetching Entra ID Sign-in logs (User: $target) using Justification '$ticket'..."
    
    Invoke-AsyncAction `
        -Parameters @{ t = $target; j = $ticket } `
        -ScriptBlock { 
            if ([string]::IsNullOrWhiteSpace($t)) {
                Get-LWAEntraLog -Justification $j 
            } else {
                Get-LWAEntraLog -UserPrincipalName $t -Justification $j 
            }
        } `
        -OnCompleted {
            param($res)
            $txtRmmOutput.Text = ($res | Format-Table -AutoSize | Out-String)
        }
})

$btnRmmRevokeSession.Add_Click({
    $target = $txtRmmCloudTarget.Text
    $ticket = $txtRmmTicket.Text
    if ([string]::IsNullOrWhiteSpace($target)) { return }
    
    $txtRmmOutput.Text = "Revoking sessions for '$target' using Justification '$ticket'..."
    
    Invoke-AsyncAction `
        -Parameters @{ t = $target; j = $ticket } `
        -ScriptBlock { Revoke-LWAEntraSession -UserPrincipalName $t -Justification $j } `
        -OnCompleted {
            param($res)
            $txtRmmOutput.Text = "Sessions revoked successfully for $target."
        }
})

$btnRmmResetMFA.Add_Click({
    $target = $txtRmmCloudTarget.Text
    $ticket = $txtRmmTicket.Text
    if ([string]::IsNullOrWhiteSpace($target)) { return }
    
    $txtRmmOutput.Text = "Resetting MFA for '$target' using Justification '$ticket'..."
    
    Invoke-AsyncAction `
        -Parameters @{ t = $target; j = $ticket } `
        -ScriptBlock { Reset-LWAEntraMFA -UserPrincipalName $t -Justification $j } `
        -OnCompleted {
            param($res)
            $txtRmmOutput.Text = "MFA reset initiated for $target. They will be prompted to re-register on next login."
        }
})
