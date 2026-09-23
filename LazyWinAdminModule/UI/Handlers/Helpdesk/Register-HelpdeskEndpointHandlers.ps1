# Endpoint-oriented Helpdesk Quick Actions.

$btnGetLaps.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify a target computer.'
    if (-not $target) { return }

    Invoke-HelpdeskUiAction "Fetching LAPS password for $target..." {
        Get-LWALapsPassword -ComputerName $target
    }
})

$btnStartRdp.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify a target computer.'
    if (-not $target) { return }

    Invoke-HelpdeskUiAction "Starting Remote Desktop to $target..." {
        Start-LWARemoteDesktop -ComputerName $target
    }
})

$btnQuickAssist.Add_Click({
    Invoke-HelpdeskUiAction 'Launching Windows Quick Assist...' {
        Start-LWAQuickAssist
    }
})

$btnRestartComputer.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify a target computer.'
    if (-not $target) { return }

    Invoke-HelpdeskUiAction "Sending restart command to $target..." {
        Restart-LWAComputer -ComputerName $target
    }
})

$btnRemoteCommand.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify a target computer.'
    if (-not $target) { return }
    Write-HelpdeskOutput 'Remote Command UI placeholder - not fully implemented in UI.'
})

$btnGpUpdate.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify a target computer.'
    if (-not $target) { return }

    Invoke-HelpdeskUiAction "Forcing GPUpdate on $target..." {
        Invoke-LWAComputerGPUpdate -ComputerName $target
    }
})

$btnFlushDns.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify a target computer.'
    if (-not $target) { return }

    Invoke-HelpdeskUiAction "Flushing DNS cache on $target..." {
        Clear-LWAComputerDnsCache -ComputerName $target
    }
})

$btnUninstallSoftware.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify a target computer.'
    if (-not $target) { return }

    $softwareName = [Microsoft.VisualBasic.Interaction]::InputBox(
        'Enter the Software Name to uninstall:',
        'Silent Uninstall',
        'SoftwareName'
    )
    if ([string]::IsNullOrWhiteSpace($softwareName)) { return }

    Invoke-HelpdeskUiAction "Initiating silent uninstall of $softwareName on $target..." {
        Uninstall-LWAComputerSoftware -ComputerName $target -SoftwareName $softwareName
    }
})

$btnForceUpdates.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify a target computer.'
    if (-not $target) { return }

    Invoke-HelpdeskUiAction "Forcing Windows Update search and install on $target..." {
        Install-LWAComputerUpdate -ComputerName $target
    }
})

$btnSendPopup.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify a target computer.'
    if (-not $target) { return }

    $message = [Microsoft.VisualBasic.Interaction]::InputBox(
        'Enter the message to broadcast to users:',
        'Broadcast Message',
        'Please save your work and log off.'
    )
    if ([string]::IsNullOrWhiteSpace($message)) { return }

    Invoke-HelpdeskUiAction "Sending popup to users on $target..." {
        Send-LWAUserMessage -ComputerName $target -Message $message
    }
})
