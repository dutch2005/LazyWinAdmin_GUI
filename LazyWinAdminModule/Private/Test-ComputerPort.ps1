function Test-ComputerPort {
    <#
    .SYNOPSIS
        Tests whether a TCP port on a remote computer is reachable within a given timeout.

    .DESCRIPTION
        Creates a TcpClient and initiates a non-blocking connection attempt using
        BeginConnect / AsyncWaitHandle.WaitOne rather than a synchronous Connect call.

        Why BeginConnect/AsyncWaitHandle instead of Connect():
            TcpClient.Connect() blocks the calling thread indefinitely until the OS
            TCP stack either establishes the connection or gives up (which on Windows
            can take 20+ seconds per RFC 793 retransmission rules). In a runspace-based
            UI like LazyWinAdmin, blocking the thread freezes the dispatcher. The async
            pattern lets WaitOne honour -TimeoutMs so the call always returns promptly,
            keeping the UI responsive. The $waitResult variable captures the Boolean
            returned by WaitOne (true = signalled within timeout) but the definitive
            success indicator is TcpClient.Connected, which is checked immediately after.

        Return values are plain strings so they can be displayed directly in the UI
        without further formatting.

    .PARAMETER ComputerName
        The hostname or IP address of the target computer. Mandatory.
        Accepts pipeline input.

    .PARAMETER Port
        The TCP port number to test. Must be in the range 1–65535.
        Defaults to 80 (HTTP).

    .PARAMETER TimeoutMs
        Maximum time in milliseconds to wait for the TCP handshake to complete.
        Defaults to 2000 (2 seconds). Lower values give faster results on
        unreachable hosts but may produce false "Closed/Filtered" results on
        high-latency links.

    .OUTPUTS
        System.String
        "Open"            — TCP connection was successfully established.
        "Closed/Filtered" — Connection was refused or the timeout elapsed with no response.
        "Error"           — An exception was thrown (e.g. DNS resolution failure).

    .EXAMPLE
        Test-ComputerPort -ComputerName "SERVER01"
        Tests whether port 80 is open on SERVER01 (2-second timeout).

    .EXAMPLE
        Test-ComputerPort -ComputerName "SERVER01" -Port 3389 -TimeoutMs 1000
        Tests whether RDP (port 3389) is reachable on SERVER01 within 1 second.

    .EXAMPLE
        "SERVER01","SERVER02" | Test-ComputerPort -Port 445
        Tests whether SMB (port 445) is open on each piped computer name.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$ComputerName,

        [int]$Port = 80,

        [int]$TimeoutMs = 2000
    )

    process {
        $tcpClient = $null
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $connectTask = $tcpClient.BeginConnect($ComputerName, $Port, $null, $null)

            # Non-blocking wait with timeout to prevent hanging the runspace
            $waitResult = $connectTask.AsyncWaitHandle.WaitOne($TimeoutMs, $false)

            if ($tcpClient.Connected) {
                $tcpClient.EndConnect($connectTask)
                return "Open"
            }
            else {
                return "Closed/Filtered"
            }
        }
        catch {
            Write-Verbose "Port test failed for $ComputerName on port $Port : $_"
            return "Error"
        }
        finally {
            if ($null -ne $tcpClient) {
                $tcpClient.Dispose()
            }
        }
    }
}
