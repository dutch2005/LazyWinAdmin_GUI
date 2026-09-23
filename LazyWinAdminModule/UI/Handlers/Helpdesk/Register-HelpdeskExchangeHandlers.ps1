# Exchange-oriented Helpdesk Quick Actions.

$btnMessageTrace.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify a sender or recipient email address.'
    if (-not $target) { return }

    Invoke-HelpdeskUiAction "Running Message Trace for $target..." {
        Get-LWAMessageTrace -SenderAddress $target
    }
})

$btnMailboxStats.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify a Mailbox Identity.'
    if (-not $target) { return }

    Invoke-HelpdeskUiAction "Fetching Mailbox Stats for $target..." {
        Get-LWAMailboxStatistics -Identity $target
    }
})

$btnExchangeBlockDomain.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify a domain or email to block.'
    if (-not $target) { return }

    Invoke-HelpdeskUiAction "Adding $target to Exchange Block List..." {
        Add-LWAExchangeBlockListDomain -Entries @($target)
    }
})

$btnGetAutoReply.Add_Click({
    $target = Get-HelpdeskTarget 'Please specify a Mailbox Identity.'
    if (-not $target) { return }

    Invoke-HelpdeskUiAction "Fetching Auto Reply for $target..." {
        Get-LWAExchangeAutoReply -Identity $target
    }
})
