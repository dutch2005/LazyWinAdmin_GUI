function Get-LWAMessageTrace {
    <#
    .SYNOPSIS
        Retrieves message trace data from Exchange Online.
    #>
    [CmdletBinding()]
    param (
        [string]$SenderAddress,
        [string]$RecipientAddress,
        [datetime]$StartDate = (Get-Date).AddDays(-2),
        [datetime]$EndDate = (Get-Date)
    )
    process {
        Assert-ModuleRequirement -ModuleName 'ExchangeOnlineManagement' -MinimumVersion '3.0.0' | Out-Null
        $params = @{ StartDate = $StartDate; EndDate = $EndDate; ErrorAction = 'Stop' }
        if ($SenderAddress) { $params.SenderAddress = $SenderAddress }
        if ($RecipientAddress) { $params.RecipientAddress = $RecipientAddress }
        return Get-MessageTrace @params | Select-Object Received, SenderAddress, RecipientAddress, Subject, Status
    }
}
