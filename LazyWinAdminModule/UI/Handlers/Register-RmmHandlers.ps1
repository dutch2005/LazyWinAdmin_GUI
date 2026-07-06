# LazyWinAdmin UI section - RMM & PIM handlers.
# Dot-sourced by Start-LazyWinAdmin INTO its scope.

$RmmInitScript = [scriptblock]::Create("Import-Module '$($PrivatePath)\..\LazyWinAdminModule.psm1' -Force")

# --- ON-PREMISE RMM HANDLERS ---

$btnRmmProcess.Add_Click({
    $comp = $txtRmmComputer.Text
    if ([string]::IsNullOrWhiteSpace($comp)) { return }
    $txtRmmOutput.Text = "Fetching processes for $comp..."
    
    Invoke-AsyncAction `
        -InitializationScript $RmmInitScript `
        -Parameters @{ c = $comp } `
        -ScriptBlock { Get-LWAComputerProcess -ComputerName $c | Format-Table -AutoSize | Out-String } `
        -OnCompleted {
            param($res)
            $txtRmmOutput.Text = $res
        }
})

$btnRmmEventLog.Add_Click({
    $comp = $txtRmmComputer.Text
    if ([string]::IsNullOrWhiteSpace($comp)) { return }
    $txtRmmOutput.Text = "Fetching event logs for $comp..."
    
    Invoke-AsyncAction `
        -InitializationScript $RmmInitScript `
        -Parameters @{ c = $comp } `
        -ScriptBlock { Get-LWAComputerEventLog -ComputerName $c | Format-Table -AutoSize | Out-String } `
        -OnCompleted {
            param($res)
            $txtRmmOutput.Text = $res
        }
})

$btnRmmVolume.Add_Click({
    $comp = $txtRmmComputer.Text
    if ([string]::IsNullOrWhiteSpace($comp)) { return }
    $txtRmmOutput.Text = "Fetching volumes for $comp..."
    
    Invoke-AsyncAction `
        -InitializationScript $RmmInitScript `
        -Parameters @{ c = $comp } `
        -ScriptBlock { Get-LWAComputerVolume -ComputerName $c | Format-Table -AutoSize | Out-String } `
        -OnCompleted {
            param($res)
            $txtRmmOutput.Text = $res
        }
})

$btnRmmSmb.Add_Click({
    $comp = $txtRmmComputer.Text
    if ([string]::IsNullOrWhiteSpace($comp)) { return }
    $txtRmmOutput.Text = "Fetching SMB sessions for $comp..."
    
    Invoke-AsyncAction `
        -InitializationScript $RmmInitScript `
        -Parameters @{ c = $comp } `
        -ScriptBlock { Get-LWAComputerSmbSession -ComputerName $c | Format-Table -AutoSize | Out-String } `
        -OnCompleted {
            param($res)
            $txtRmmOutput.Text = $res
        }
})

$btnRmmUpdates.Add_Click({
    $comp = $txtRmmComputer.Text
    if ([string]::IsNullOrWhiteSpace($comp)) { return }
    $txtRmmOutput.Text = "Fetching pending Windows Updates for $comp..."
    
    Invoke-AsyncAction `
        -InitializationScript $RmmInitScript `
        -Parameters @{ c = $comp } `
        -ScriptBlock { Get-LWAComputerUpdate -ComputerName $c | Format-Table -AutoSize | Out-String } `
        -OnCompleted {
            param($res)
            $txtRmmOutput.Text = $res
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
        -InitializationScript $RmmInitScript `
        -Parameters @{ t = $target; j = $ticket } `
        -ScriptBlock { Get-LWABitLockerKey -DeviceId $t -Justification $j | Format-List | Out-String } `
        -OnCompleted {
            param($res)
            $txtRmmOutput.Text = $res
        }
})

$btnRmmIntuneSync.Add_Click({
    $target = $txtRmmCloudTarget.Text
    $ticket = $txtRmmTicket.Text
    if ([string]::IsNullOrWhiteSpace($target)) { return }
    
    $txtRmmOutput.Text = "Triggering Intune Sync for device '$target' using Justification '$ticket'..."
    
    Invoke-AsyncAction `
        -InitializationScript $RmmInitScript `
        -Parameters @{ t = $target; j = $ticket } `
        -ScriptBlock { Invoke-LWAIntuneAction -DeviceId $t -Action "Sync" -Justification $j | Out-String } `
        -OnCompleted {
            param($res)
            $txtRmmOutput.Text = "Intune Sync initiated successfully. $($res)"
        }
})

$btnRmmEntraLogs.Add_Click({
    $target = $txtRmmCloudTarget.Text
    $ticket = $txtRmmTicket.Text
    
    $txtRmmOutput.Text = "Fetching Entra ID Sign-in logs (User: $target) using Justification '$ticket'..."
    
    Invoke-AsyncAction `
        -InitializationScript $RmmInitScript `
        -Parameters @{ t = $target; j = $ticket } `
        -ScriptBlock { 
            if ([string]::IsNullOrWhiteSpace($t)) {
                Get-LWAEntraLog -Justification $j | Format-Table -AutoSize | Out-String
            } else {
                Get-LWAEntraLog -UserPrincipalName $t -Justification $j | Format-Table -AutoSize | Out-String
            }
        } `
        -OnCompleted {
            param($res)
            $txtRmmOutput.Text = $res
        }
})

$btnRmmRevokeSession.Add_Click({
    $target = $txtRmmCloudTarget.Text
    $ticket = $txtRmmTicket.Text
    if ([string]::IsNullOrWhiteSpace($target)) { return }
    
    $txtRmmOutput.Text = "Revoking sessions for '$target' using Justification '$ticket'..."
    
    Invoke-AsyncAction `
        -InitializationScript $RmmInitScript `
        -Parameters @{ t = $target; j = $ticket } `
        -ScriptBlock { Revoke-LWAEntraSession -UserPrincipalName $t -Justification $j | Out-String } `
        -OnCompleted {
            param($res)
            $txtRmmOutput.Text = "Sessions revoked successfully for $target. $($res)"
        }
})

$btnRmmResetMFA.Add_Click({
    $target = $txtRmmCloudTarget.Text
    $ticket = $txtRmmTicket.Text
    if ([string]::IsNullOrWhiteSpace($target)) { return }
    
    $txtRmmOutput.Text = "Resetting MFA for '$target' using Justification '$ticket'..."
    
    Invoke-AsyncAction `
        -InitializationScript $RmmInitScript `
        -Parameters @{ t = $target; j = $ticket } `
        -ScriptBlock { Reset-LWAEntraMFA -UserPrincipalName $t -Justification $j | Out-String } `
        -OnCompleted {
            param($res)
            $txtRmmOutput.Text = "MFA reset initiated for $target. They will be prompted to re-register on next login. $($res)"
        }
})
