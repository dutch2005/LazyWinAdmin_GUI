function Get-LWAExchangeAutoReply {
    <#
    .SYNOPSIS
        Retrieves the Out of Office (Auto Reply) status and message for a mailbox.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Identity
    )
    process {
        Assert-ModuleRequirement -ModuleName 'ExchangeOnlineManagement' -MinimumVersion '3.0.0' | Out-Null
        
        $config = Get-MailboxAutoReplyConfiguration -Identity $Identity -ErrorAction Stop
        return $config | Select-Object AutoReplyState, StartTime, EndTime, InternalMessage, ExternalMessage
    }
}
