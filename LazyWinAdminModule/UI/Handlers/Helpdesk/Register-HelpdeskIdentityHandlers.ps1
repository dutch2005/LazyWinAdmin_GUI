# Identity-oriented Helpdesk Quick Actions.

$btnUnlockAd.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify an AD SamAccountName.'
    if (-not $target) { return }

    Invoke-HelpdeskUiAction "Unlocking AD account for $target..." {
        Unlock-LWAADAccount -SamAccountName $target
    }
})

$btnResetAdPassword.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify an AD SamAccountName.'
    if (-not $target) { return }

    Write-HelpdeskOutput 'Reset Password UI requires securely prompting for a password. Skipping direct execution.'
})

$btnEntraSync.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify your AD Connect Server hostname.'
    if (-not $target) { return }

    Invoke-HelpdeskUiAction "Triggering Delta Sync on $target..." {
        Start-LWAEntraSync -AadConnectServerName $target
    }
})

$btnSetTenant.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify an Entra ID Tenant ID.'
    if (-not $target) { return }

    Invoke-HelpdeskUiAction "Switching Entra ID context to Tenant $target..." {
        Set-LWAEntraTenant -TenantId $target
    }
})
