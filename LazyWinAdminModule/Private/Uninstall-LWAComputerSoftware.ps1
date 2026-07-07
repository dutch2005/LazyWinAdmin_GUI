function Uninstall-LWAComputerSoftware {
    <#
    .SYNOPSIS
        Silently uninstalls software from a remote computer using WMI.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,
        [Parameter(Mandatory=$true)]
        [string]$SoftwareName
    )
    process {
        $app = Get-CimInstance -ClassName Win32_Product -ComputerName $ComputerName -Filter "Name LIKE '%$SoftwareName%'" -ErrorAction Stop
        if (-not $app) { throw "Software matching '$SoftwareName' not found on $ComputerName." }
        
        $res = Invoke-CimMethod -InputObject $app -MethodName Uninstall
        if ($res.ReturnValue -eq 0) {
            return "[OK] Successfully initiated silent uninstall of $($app.Name) on $ComputerName."
        } else {
            return "[!] Uninstall failed with return code: $($res.ReturnValue)"
        }
    }
}
