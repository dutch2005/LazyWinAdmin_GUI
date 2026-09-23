# Session and printer Helpdesk Quick Actions.

$btnGetPrinter.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify a target computer.'
    if (-not $target) { return }

    Invoke-HelpdeskUiAction "Fetching printers from $target..." {
        Get-LWAComputerPrinter -ComputerName $target
    }
})

$btnRestartSpooler.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify a target computer.'
    if (-not $target) { return }

    Invoke-HelpdeskUiAction "Restarting Print Spooler on $target..." {
        Restart-LWAPrintSpooler -ComputerName $target
    }
})

$btnForceLogoff.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify a target computer.'
    if (-not $target) { return }

    Invoke-HelpdeskUiAction "Forcing user logoff on $target..." {
        Invoke-LWALogoff -ComputerName $target
    }
})

$btnLockWorkstation.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify a target computer.'
    if (-not $target) { return }

    Invoke-HelpdeskUiAction "Locking workstation on $target..." {
        Lock-LWAComputer -ComputerName $target
    }
})
