function Test-ComputerPort {
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
            $tcpClient   = New-Object System.Net.Sockets.TcpClient
            $connectTask = $tcpClient.BeginConnect($ComputerName, $Port, $null, $null)

            # Wait for the async connect, but no longer than $TimeoutMs.
            # WaitOne returns $true  = handle was signaled (connect completed, either OK or error)
            #                $false = timed out, connect still pending in the background
            # When it times out we must NOT call EndConnect — that would block the runspace
            # waiting for the very operation the timeout was meant to abandon. The `finally`
            # block disposes the TcpClient, which cancels the pending connect.
            $waitResult = $connectTask.AsyncWaitHandle.WaitOne($TimeoutMs, $false)

            if (-not $waitResult) {
                return "Closed/Filtered"
            }

            # Handle signaled. EndConnect either succeeds (socket is open) or throws a
            # SocketException for connect-level failures (ECONNREFUSED, host unreachable,
            # RST). Both are expected results of a reachability probe and map to
            # "Closed/Filtered". Only unexpected framework/runtime errors fall through
            # to the outer catch and surface as "Error".
            try {
                $tcpClient.EndConnect($connectTask)
                return "Open"
            }
            catch [System.Net.Sockets.SocketException] {
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