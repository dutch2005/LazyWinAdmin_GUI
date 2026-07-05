function Invoke-ComputerServiceControl {
    <#
    .SYNOPSIS
        Starts, stops, or restarts a Windows service on a local or remote computer.
    .DESCRIPTION
        Verifies the service exists via Get-CimInstance, then invokes Win32_Service
        CIM methods using a WQL query. Using -Query (not -InputObject) avoids the
        CimInstance type constraint so the function is fully mockable in Pester tests.
        Detects local targets and omits -ComputerName to avoid WinRM dependency on
        the local machine (consistent with all other CIM-based private functions).
        All three operations require local Administrator rights on the target machine.
    .PARAMETER ComputerName
        Target computer. Accepts 'localhost', '127.0.0.1', or $env:COMPUTERNAME for
        direct in-process CIM access without WinRM.
    .PARAMETER ServiceName
        Short service name (e.g. 'wuauserv'), not the display name.
    .PARAMETER Action
        One of: Start, Stop, Restart.
    .OUTPUTS
        System.String — [OK] message on success, [!] on non-zero return code, Error: on exception.
    .EXAMPLE
        Invoke-ComputerServiceControl -ComputerName PC01 -ServiceName wuauserv -Action Restart
        Returns "[OK] Service 'wuauserv' Restarted successfully on PC01."
    .EXAMPLE
        Invoke-ComputerServiceControl -ComputerName localhost -ServiceName spooler -Action Stop
        Returns "[OK] Service 'spooler' Stopped successfully on localhost."
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [string] $ComputerName,
        [Parameter(Mandatory)] [string] $ServiceName,
        [Parameter(Mandatory)] [ValidateSet('Start', 'Stop', 'Restart')] [string] $Action
    )

    $pastTense = @{ Start = 'Started'; Stop = 'Stopped'; Restart = 'Restarted' }
    $isLocal   = $ComputerName -iin @('localhost', '127.0.0.1', $env:COMPUTERNAME)

    try {
        # Verify service exists before attempting to control it
        $checkParams = @{ ClassName = 'Win32_Service'; Filter = "Name='$ServiceName'"; ErrorAction = 'Stop' }
        if (-not $isLocal) { $checkParams.ComputerName = $ComputerName }
        $svc = Get-CimInstance @checkParams
        if (-not $svc) {
            return "[!] Service '$ServiceName' not found on $ComputerName."
        }

        # Use -Query to invoke the instance method.  -Query accepts a plain string so
        # Pester mocks can intercept the call without a real CimInstance.
        $query      = "SELECT * FROM Win32_Service WHERE Name='$ServiceName'"
        $cimInvoke  = @{ Query = $query; ErrorAction = 'Stop' }
        if (-not $isLocal) { $cimInvoke.ComputerName = $ComputerName }

        if ($Action -eq 'Restart') {
            $stop = Invoke-CimMethod @cimInvoke -MethodName 'StopService'
            if ($stop.ReturnValue -ne 0) {
                return "[!] Stop returned code $($stop.ReturnValue) for '$ServiceName' on $ComputerName."
            }
            Start-Sleep -Seconds 2
            $result = Invoke-CimMethod @cimInvoke -MethodName 'StartService'
        } elseif ($Action -eq 'Start') {
            $result = Invoke-CimMethod @cimInvoke -MethodName 'StartService'
        } else {
            $result = Invoke-CimMethod @cimInvoke -MethodName 'StopService'
        }

        if ($result.ReturnValue -eq 0) {
            return "[OK] Service '$ServiceName' $($pastTense[$Action]) successfully on $ComputerName."
        } else {
            return "[!] Service '$ServiceName' $Action returned code $($result.ReturnValue) on $ComputerName."
        }
    }
    catch {
        return "Error: $($_.Exception.Message)"
    }
}
