function Get-LocalOrRemoteCimSession {
    <#
    .SYNOPSIS
        Returns a CimSession bound to the local machine or the named remote.
    .DESCRIPTION
        Centralizes the "is this actually local?" short-circuit so callers
        don't each re-derive it. Honours the cim_session.* ALWAYS
        reuse-before-create contract by allowing callers to supply an
        existing session via -ReuseSession.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimSession])]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Microsoft.Management.Infrastructure.CimSession]$ReuseSession
    )

    if ($ReuseSession) { return $ReuseSession }

    $isLocal = $ComputerName -iin @('localhost', '127.0.0.1', $env:COMPUTERNAME)
    if ($isLocal) {
        return New-CimSession -ErrorAction Stop
    }
    return New-CimSession -ComputerName $ComputerName -ErrorAction Stop
}
