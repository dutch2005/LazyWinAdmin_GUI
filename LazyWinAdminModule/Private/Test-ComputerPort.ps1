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