function Register-HelpdeskHandlers {
    <#
    .SYNOPSIS
        Hooks up UI events for the Helpdesk Quick Actions tab.
    #>
    Add-Type -AssemblyName Microsoft.VisualBasic
    
    
    function Log-HelpdeskOutput {
        param([string]$Message)
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $txtHelpdeskOutput.Text = "[$timestamp] $Message`r`n" + $txtHelpdeskOutput.Text
    }

    $btnGetLaps.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Fetching LAPS password for $target..."
        # Run asynchronously to avoid blocking UI
        $runspace = [powershell]::Create().AddScript({
            param($target)
            return Get-LWALapsPassword -ComputerName $target
        }).AddArgument($target)
        
        $runspace.BeginInvoke($null, $null) | Out-Null
        Log-HelpdeskOutput "Command launched..."
    })

    $btnStartRdp.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Starting Remote Desktop to $target..."
        Start-LWARemoteDesktop -ComputerName $target | Out-Null
    })

    $btnQuickAssist.Add_Click({
        Log-HelpdeskOutput "Launching Windows Quick Assist..."
        Start-LWAQuickAssist | Out-Null
    })

    $btnRestartComputer.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Sending Restart command to $target..."
        try {
            $res = Restart-LWAComputer -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnRemoteCommand.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Remote Command UI placeholder - not fully implemented in UI."
    })

    $btnGpUpdate.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Forcing GPUpdate on $target..."
        try {
            $res = Invoke-LWAComputerGPUpdate -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnFlushDns.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Flushing DNS on $target..."
        try {
            $res = Clear-LWAComputerDnsCache -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnGetPrinter.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Fetching printers from $target..."
        try {
            $res = Get-LWAComputerPrinter -ComputerName $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnRestartSpooler.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Restarting Print Spooler on $target..."
        try {
            $res = Restart-LWAPrintSpooler -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnUnlockAd.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify an AD SamAccountName."; return }
        Log-HelpdeskOutput "Unlocking AD account for $target..."
        try {
            $res = Unlock-LWAADAccount -SamAccountName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnResetAdPassword.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify an AD SamAccountName."; return }
        Log-HelpdeskOutput "Reset Password UI requires securely prompting for a password. Skipping direct execution."
        # In a real UI we would popup a window asking for the new password as SecureString
    })

    $btnEntraSync.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify your AD Connect Server hostname."; return }
        Log-HelpdeskOutput "Triggering Delta Sync on $target..."
        try {
            $res = Start-LWAEntraSync -AadConnectServerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnMessageTrace.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a sender or recipient email address."; return }
        Log-HelpdeskOutput "Running Message Trace for $target..."
        try {
            $res = Get-LWAMessageTrace -SenderAddress $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnMailboxStats.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a Mailbox Identity."; return }
        Log-HelpdeskOutput "Fetching Mailbox Stats for $target..."
        try {
            $res = Get-LWAMailboxStatistics -Identity $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnExchangeBlockDomain.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a domain or email to block."; return }
        Log-HelpdeskOutput "Adding $target to Exchange Block List..."
        try {
            $res = Add-LWAExchangeBlockListDomain -Entries @($target)
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnGetAutoReply.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a Mailbox Identity."; return }
        Log-HelpdeskOutput "Fetching Auto Reply for $target..."
        try {
            $res = Get-LWAExchangeAutoReply -Identity $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnUninstallSoftware.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        # Let's prompt for software name (simple input box)
        $softwareName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the Software Name to uninstall:", "Silent Uninstall", "SoftwareName")
        if (-not $softwareName) { return }
        Log-HelpdeskOutput "Initiating silent uninstall of $softwareName on $target..."
        try {
            $res = Uninstall-LWAComputerSoftware -ComputerName $target -SoftwareName $softwareName
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: function Register-HelpdeskHandlers {
    <#
    .SYNOPSIS
        Hooks up UI events for the Helpdesk Quick Actions tab.
    #>
    
    function Log-HelpdeskOutput {
        param([string]$Message)
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $txtHelpdeskOutput.Text = "[$timestamp] $Message`r`n" + $txtHelpdeskOutput.Text
    }

    $btnGetLaps.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Fetching LAPS password for $target..."
        # Run asynchronously to avoid blocking UI
        $runspace = [powershell]::Create().AddScript({
            param($target)
            return Get-LWALapsPassword -ComputerName $target
        }).AddArgument($target)
        
        $runspace.BeginInvoke($null, $null) | Out-Null
        Log-HelpdeskOutput "Command launched..."
    })

    $btnStartRdp.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Starting Remote Desktop to $target..."
        Start-LWARemoteDesktop -ComputerName $target | Out-Null
    })

    $btnQuickAssist.Add_Click({
        Log-HelpdeskOutput "Launching Windows Quick Assist..."
        Start-LWAQuickAssist | Out-Null
    })

    $btnRestartComputer.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Sending Restart command to $target..."
        try {
            $res = Restart-LWAComputer -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnRemoteCommand.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Remote Command UI placeholder - not fully implemented in UI."
    })

    $btnGpUpdate.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Forcing GPUpdate on $target..."
        try {
            $res = Invoke-LWAComputerGPUpdate -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnFlushDns.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Flushing DNS on $target..."
        try {
            $res = Clear-LWAComputerDnsCache -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnGetPrinter.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Fetching printers from $target..."
        try {
            $res = Get-LWAComputerPrinter -ComputerName $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnRestartSpooler.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Restarting Print Spooler on $target..."
        try {
            $res = Restart-LWAPrintSpooler -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnUnlockAd.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify an AD SamAccountName."; return }
        Log-HelpdeskOutput "Unlocking AD account for $target..."
        try {
            $res = Unlock-LWAADAccount -SamAccountName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnResetAdPassword.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify an AD SamAccountName."; return }
        Log-HelpdeskOutput "Reset Password UI requires securely prompting for a password. Skipping direct execution."
        # In a real UI we would popup a window asking for the new password as SecureString
    })

    $btnEntraSync.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify your AD Connect Server hostname."; return }
        Log-HelpdeskOutput "Triggering Delta Sync on $target..."
        try {
            $res = Start-LWAEntraSync -AadConnectServerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnMessageTrace.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a sender or recipient email address."; return }
        Log-HelpdeskOutput "Running Message Trace for $target..."
        try {
            $res = Get-LWAMessageTrace -SenderAddress $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnMailboxStats.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a Mailbox Identity."; return }
        Log-HelpdeskOutput "Fetching Mailbox Stats for $target..."
        try {
            $res = Get-LWAMailboxStatistics -Identity $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnExchangeBlockDomain.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a domain or email to block."; return }
        Log-HelpdeskOutput "Adding $target to Exchange Block List..."
        try {
            $res = Add-LWAExchangeBlockListDomain -Entries @($target)
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnGetAutoReply.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a Mailbox Identity."; return }
        Log-HelpdeskOutput "Fetching Auto Reply for $target..."
        try {
            $res = Get-LWAExchangeAutoReply -Identity $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })
}
"
        }
    })

    $btnForceUpdates.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Forcing Windows Update search and install on $target..."
        try {
            $res = Install-LWAComputerUpdate -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: function Register-HelpdeskHandlers {
    <#
    .SYNOPSIS
        Hooks up UI events for the Helpdesk Quick Actions tab.
    #>
    
    function Log-HelpdeskOutput {
        param([string]$Message)
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $txtHelpdeskOutput.Text = "[$timestamp] $Message`r`n" + $txtHelpdeskOutput.Text
    }

    $btnGetLaps.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Fetching LAPS password for $target..."
        # Run asynchronously to avoid blocking UI
        $runspace = [powershell]::Create().AddScript({
            param($target)
            return Get-LWALapsPassword -ComputerName $target
        }).AddArgument($target)
        
        $runspace.BeginInvoke($null, $null) | Out-Null
        Log-HelpdeskOutput "Command launched..."
    })

    $btnStartRdp.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Starting Remote Desktop to $target..."
        Start-LWARemoteDesktop -ComputerName $target | Out-Null
    })

    $btnQuickAssist.Add_Click({
        Log-HelpdeskOutput "Launching Windows Quick Assist..."
        Start-LWAQuickAssist | Out-Null
    })

    $btnRestartComputer.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Sending Restart command to $target..."
        try {
            $res = Restart-LWAComputer -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnRemoteCommand.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Remote Command UI placeholder - not fully implemented in UI."
    })

    $btnGpUpdate.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Forcing GPUpdate on $target..."
        try {
            $res = Invoke-LWAComputerGPUpdate -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnFlushDns.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Flushing DNS on $target..."
        try {
            $res = Clear-LWAComputerDnsCache -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnGetPrinter.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Fetching printers from $target..."
        try {
            $res = Get-LWAComputerPrinter -ComputerName $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnRestartSpooler.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Restarting Print Spooler on $target..."
        try {
            $res = Restart-LWAPrintSpooler -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnUnlockAd.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify an AD SamAccountName."; return }
        Log-HelpdeskOutput "Unlocking AD account for $target..."
        try {
            $res = Unlock-LWAADAccount -SamAccountName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnResetAdPassword.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify an AD SamAccountName."; return }
        Log-HelpdeskOutput "Reset Password UI requires securely prompting for a password. Skipping direct execution."
        # In a real UI we would popup a window asking for the new password as SecureString
    })

    $btnEntraSync.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify your AD Connect Server hostname."; return }
        Log-HelpdeskOutput "Triggering Delta Sync on $target..."
        try {
            $res = Start-LWAEntraSync -AadConnectServerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnMessageTrace.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a sender or recipient email address."; return }
        Log-HelpdeskOutput "Running Message Trace for $target..."
        try {
            $res = Get-LWAMessageTrace -SenderAddress $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnMailboxStats.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a Mailbox Identity."; return }
        Log-HelpdeskOutput "Fetching Mailbox Stats for $target..."
        try {
            $res = Get-LWAMailboxStatistics -Identity $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnExchangeBlockDomain.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a domain or email to block."; return }
        Log-HelpdeskOutput "Adding $target to Exchange Block List..."
        try {
            $res = Add-LWAExchangeBlockListDomain -Entries @($target)
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnGetAutoReply.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a Mailbox Identity."; return }
        Log-HelpdeskOutput "Fetching Auto Reply for $target..."
        try {
            $res = Get-LWAExchangeAutoReply -Identity $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })
}
"
        }
    })

    $btnSendPopup.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        $message = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the message to broadcast to users:", "Broadcast Message", "Please save your work and log off.")
        if (-not $message) { return }
        Log-HelpdeskOutput "Sending popup to users on $target..."
        try {
            $res = Send-LWAUserMessage -ComputerName $target -Message $message
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: function Register-HelpdeskHandlers {
    <#
    .SYNOPSIS
        Hooks up UI events for the Helpdesk Quick Actions tab.
    #>
    
    function Log-HelpdeskOutput {
        param([string]$Message)
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $txtHelpdeskOutput.Text = "[$timestamp] $Message`r`n" + $txtHelpdeskOutput.Text
    }

    $btnGetLaps.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Fetching LAPS password for $target..."
        # Run asynchronously to avoid blocking UI
        $runspace = [powershell]::Create().AddScript({
            param($target)
            return Get-LWALapsPassword -ComputerName $target
        }).AddArgument($target)
        
        $runspace.BeginInvoke($null, $null) | Out-Null
        Log-HelpdeskOutput "Command launched..."
    })

    $btnStartRdp.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Starting Remote Desktop to $target..."
        Start-LWARemoteDesktop -ComputerName $target | Out-Null
    })

    $btnQuickAssist.Add_Click({
        Log-HelpdeskOutput "Launching Windows Quick Assist..."
        Start-LWAQuickAssist | Out-Null
    })

    $btnRestartComputer.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Sending Restart command to $target..."
        try {
            $res = Restart-LWAComputer -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnRemoteCommand.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Remote Command UI placeholder - not fully implemented in UI."
    })

    $btnGpUpdate.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Forcing GPUpdate on $target..."
        try {
            $res = Invoke-LWAComputerGPUpdate -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnFlushDns.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Flushing DNS on $target..."
        try {
            $res = Clear-LWAComputerDnsCache -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnGetPrinter.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Fetching printers from $target..."
        try {
            $res = Get-LWAComputerPrinter -ComputerName $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnRestartSpooler.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Restarting Print Spooler on $target..."
        try {
            $res = Restart-LWAPrintSpooler -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnUnlockAd.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify an AD SamAccountName."; return }
        Log-HelpdeskOutput "Unlocking AD account for $target..."
        try {
            $res = Unlock-LWAADAccount -SamAccountName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnResetAdPassword.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify an AD SamAccountName."; return }
        Log-HelpdeskOutput "Reset Password UI requires securely prompting for a password. Skipping direct execution."
        # In a real UI we would popup a window asking for the new password as SecureString
    })

    $btnEntraSync.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify your AD Connect Server hostname."; return }
        Log-HelpdeskOutput "Triggering Delta Sync on $target..."
        try {
            $res = Start-LWAEntraSync -AadConnectServerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnMessageTrace.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a sender or recipient email address."; return }
        Log-HelpdeskOutput "Running Message Trace for $target..."
        try {
            $res = Get-LWAMessageTrace -SenderAddress $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnMailboxStats.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a Mailbox Identity."; return }
        Log-HelpdeskOutput "Fetching Mailbox Stats for $target..."
        try {
            $res = Get-LWAMailboxStatistics -Identity $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnExchangeBlockDomain.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a domain or email to block."; return }
        Log-HelpdeskOutput "Adding $target to Exchange Block List..."
        try {
            $res = Add-LWAExchangeBlockListDomain -Entries @($target)
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnGetAutoReply.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a Mailbox Identity."; return }
        Log-HelpdeskOutput "Fetching Auto Reply for $target..."
        try {
            $res = Get-LWAExchangeAutoReply -Identity $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })
}
"
        }
    })

    $btnForceLogoff.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Forcing user logoff on $target..."
        try {
            $res = Invoke-LWALogoff -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: function Register-HelpdeskHandlers {
    <#
    .SYNOPSIS
        Hooks up UI events for the Helpdesk Quick Actions tab.
    #>
    
    function Log-HelpdeskOutput {
        param([string]$Message)
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $txtHelpdeskOutput.Text = "[$timestamp] $Message`r`n" + $txtHelpdeskOutput.Text
    }

    $btnGetLaps.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Fetching LAPS password for $target..."
        # Run asynchronously to avoid blocking UI
        $runspace = [powershell]::Create().AddScript({
            param($target)
            return Get-LWALapsPassword -ComputerName $target
        }).AddArgument($target)
        
        $runspace.BeginInvoke($null, $null) | Out-Null
        Log-HelpdeskOutput "Command launched..."
    })

    $btnStartRdp.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Starting Remote Desktop to $target..."
        Start-LWARemoteDesktop -ComputerName $target | Out-Null
    })

    $btnQuickAssist.Add_Click({
        Log-HelpdeskOutput "Launching Windows Quick Assist..."
        Start-LWAQuickAssist | Out-Null
    })

    $btnRestartComputer.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Sending Restart command to $target..."
        try {
            $res = Restart-LWAComputer -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnRemoteCommand.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Remote Command UI placeholder - not fully implemented in UI."
    })

    $btnGpUpdate.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Forcing GPUpdate on $target..."
        try {
            $res = Invoke-LWAComputerGPUpdate -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnFlushDns.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Flushing DNS on $target..."
        try {
            $res = Clear-LWAComputerDnsCache -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnGetPrinter.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Fetching printers from $target..."
        try {
            $res = Get-LWAComputerPrinter -ComputerName $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnRestartSpooler.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Restarting Print Spooler on $target..."
        try {
            $res = Restart-LWAPrintSpooler -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnUnlockAd.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify an AD SamAccountName."; return }
        Log-HelpdeskOutput "Unlocking AD account for $target..."
        try {
            $res = Unlock-LWAADAccount -SamAccountName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnResetAdPassword.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify an AD SamAccountName."; return }
        Log-HelpdeskOutput "Reset Password UI requires securely prompting for a password. Skipping direct execution."
        # In a real UI we would popup a window asking for the new password as SecureString
    })

    $btnEntraSync.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify your AD Connect Server hostname."; return }
        Log-HelpdeskOutput "Triggering Delta Sync on $target..."
        try {
            $res = Start-LWAEntraSync -AadConnectServerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnMessageTrace.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a sender or recipient email address."; return }
        Log-HelpdeskOutput "Running Message Trace for $target..."
        try {
            $res = Get-LWAMessageTrace -SenderAddress $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnMailboxStats.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a Mailbox Identity."; return }
        Log-HelpdeskOutput "Fetching Mailbox Stats for $target..."
        try {
            $res = Get-LWAMailboxStatistics -Identity $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnExchangeBlockDomain.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a domain or email to block."; return }
        Log-HelpdeskOutput "Adding $target to Exchange Block List..."
        try {
            $res = Add-LWAExchangeBlockListDomain -Entries @($target)
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnGetAutoReply.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a Mailbox Identity."; return }
        Log-HelpdeskOutput "Fetching Auto Reply for $target..."
        try {
            $res = Get-LWAExchangeAutoReply -Identity $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })
}
"
        }
    })

    $btnLockWorkstation.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Locking workstation on $target..."
        try {
            $res = Lock-LWAComputer -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: function Register-HelpdeskHandlers {
    <#
    .SYNOPSIS
        Hooks up UI events for the Helpdesk Quick Actions tab.
    #>
    
    function Log-HelpdeskOutput {
        param([string]$Message)
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $txtHelpdeskOutput.Text = "[$timestamp] $Message`r`n" + $txtHelpdeskOutput.Text
    }

    $btnGetLaps.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Fetching LAPS password for $target..."
        # Run asynchronously to avoid blocking UI
        $runspace = [powershell]::Create().AddScript({
            param($target)
            return Get-LWALapsPassword -ComputerName $target
        }).AddArgument($target)
        
        $runspace.BeginInvoke($null, $null) | Out-Null
        Log-HelpdeskOutput "Command launched..."
    })

    $btnStartRdp.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Starting Remote Desktop to $target..."
        Start-LWARemoteDesktop -ComputerName $target | Out-Null
    })

    $btnQuickAssist.Add_Click({
        Log-HelpdeskOutput "Launching Windows Quick Assist..."
        Start-LWAQuickAssist | Out-Null
    })

    $btnRestartComputer.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Sending Restart command to $target..."
        try {
            $res = Restart-LWAComputer -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnRemoteCommand.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Remote Command UI placeholder - not fully implemented in UI."
    })

    $btnGpUpdate.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Forcing GPUpdate on $target..."
        try {
            $res = Invoke-LWAComputerGPUpdate -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnFlushDns.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Flushing DNS on $target..."
        try {
            $res = Clear-LWAComputerDnsCache -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnGetPrinter.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Fetching printers from $target..."
        try {
            $res = Get-LWAComputerPrinter -ComputerName $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnRestartSpooler.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Restarting Print Spooler on $target..."
        try {
            $res = Restart-LWAPrintSpooler -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnUnlockAd.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify an AD SamAccountName."; return }
        Log-HelpdeskOutput "Unlocking AD account for $target..."
        try {
            $res = Unlock-LWAADAccount -SamAccountName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnResetAdPassword.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify an AD SamAccountName."; return }
        Log-HelpdeskOutput "Reset Password UI requires securely prompting for a password. Skipping direct execution."
        # In a real UI we would popup a window asking for the new password as SecureString
    })

    $btnEntraSync.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify your AD Connect Server hostname."; return }
        Log-HelpdeskOutput "Triggering Delta Sync on $target..."
        try {
            $res = Start-LWAEntraSync -AadConnectServerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnMessageTrace.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a sender or recipient email address."; return }
        Log-HelpdeskOutput "Running Message Trace for $target..."
        try {
            $res = Get-LWAMessageTrace -SenderAddress $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnMailboxStats.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a Mailbox Identity."; return }
        Log-HelpdeskOutput "Fetching Mailbox Stats for $target..."
        try {
            $res = Get-LWAMailboxStatistics -Identity $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnExchangeBlockDomain.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a domain or email to block."; return }
        Log-HelpdeskOutput "Adding $target to Exchange Block List..."
        try {
            $res = Add-LWAExchangeBlockListDomain -Entries @($target)
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnGetAutoReply.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a Mailbox Identity."; return }
        Log-HelpdeskOutput "Fetching Auto Reply for $target..."
        try {
            $res = Get-LWAExchangeAutoReply -Identity $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })
}
"
        }
    })

    $btnSetTenant.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify an Entra ID Tenant ID."; return }
        Log-HelpdeskOutput "Switching Entra ID context to Tenant $target..."
        try {
            $res = Set-LWAEntraTenant -TenantId $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: function Register-HelpdeskHandlers {
    <#
    .SYNOPSIS
        Hooks up UI events for the Helpdesk Quick Actions tab.
    #>
    
    function Log-HelpdeskOutput {
        param([string]$Message)
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $txtHelpdeskOutput.Text = "[$timestamp] $Message`r`n" + $txtHelpdeskOutput.Text
    }

    $btnGetLaps.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Fetching LAPS password for $target..."
        # Run asynchronously to avoid blocking UI
        $runspace = [powershell]::Create().AddScript({
            param($target)
            return Get-LWALapsPassword -ComputerName $target
        }).AddArgument($target)
        
        $runspace.BeginInvoke($null, $null) | Out-Null
        Log-HelpdeskOutput "Command launched..."
    })

    $btnStartRdp.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Starting Remote Desktop to $target..."
        Start-LWARemoteDesktop -ComputerName $target | Out-Null
    })

    $btnQuickAssist.Add_Click({
        Log-HelpdeskOutput "Launching Windows Quick Assist..."
        Start-LWAQuickAssist | Out-Null
    })

    $btnRestartComputer.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Sending Restart command to $target..."
        try {
            $res = Restart-LWAComputer -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnRemoteCommand.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Remote Command UI placeholder - not fully implemented in UI."
    })

    $btnGpUpdate.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Forcing GPUpdate on $target..."
        try {
            $res = Invoke-LWAComputerGPUpdate -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnFlushDns.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Flushing DNS on $target..."
        try {
            $res = Clear-LWAComputerDnsCache -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnGetPrinter.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Fetching printers from $target..."
        try {
            $res = Get-LWAComputerPrinter -ComputerName $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnRestartSpooler.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a target computer."; return }
        Log-HelpdeskOutput "Restarting Print Spooler on $target..."
        try {
            $res = Restart-LWAPrintSpooler -ComputerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnUnlockAd.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify an AD SamAccountName."; return }
        Log-HelpdeskOutput "Unlocking AD account for $target..."
        try {
            $res = Unlock-LWAADAccount -SamAccountName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnResetAdPassword.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify an AD SamAccountName."; return }
        Log-HelpdeskOutput "Reset Password UI requires securely prompting for a password. Skipping direct execution."
        # In a real UI we would popup a window asking for the new password as SecureString
    })

    $btnEntraSync.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify your AD Connect Server hostname."; return }
        Log-HelpdeskOutput "Triggering Delta Sync on $target..."
        try {
            $res = Start-LWAEntraSync -AadConnectServerName $target
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnMessageTrace.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a sender or recipient email address."; return }
        Log-HelpdeskOutput "Running Message Trace for $target..."
        try {
            $res = Get-LWAMessageTrace -SenderAddress $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnMailboxStats.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a Mailbox Identity."; return }
        Log-HelpdeskOutput "Fetching Mailbox Stats for $target..."
        try {
            $res = Get-LWAMailboxStatistics -Identity $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnExchangeBlockDomain.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a domain or email to block."; return }
        Log-HelpdeskOutput "Adding $target to Exchange Block List..."
        try {
            $res = Add-LWAExchangeBlockListDomain -Entries @($target)
            Log-HelpdeskOutput $res
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })

    $btnGetAutoReply.Add_Click({
        $target = $txtHelpdeskTarget.Text
        if (-not $target) { Log-HelpdeskOutput "[!] Please specify a Mailbox Identity."; return }
        Log-HelpdeskOutput "Fetching Auto Reply for $target..."
        try {
            $res = Get-LWAExchangeAutoReply -Identity $target | Out-String
            Log-HelpdeskOutput "`n$res"
        } catch {
            Log-HelpdeskOutput "[!] Error: $_"
        }
    })
}
"
        }
    })

}

