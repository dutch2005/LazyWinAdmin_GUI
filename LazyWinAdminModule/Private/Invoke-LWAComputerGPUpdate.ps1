function Invoke-LWAComputerGPUpdate {
    <#
    .SYNOPSIS
        Forces a Group Policy update on a remote computer.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )
    process {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            # Execute GPUpdate and capture output. 
            # We use 'cmd /c gpupdate /force' and pipe to Out-String to avoid hangs
            cmd.exe /c "gpupdate /force" 2>&1 | Out-String
        } -ErrorAction Stop
        return "[OK] Group Policy update executed on $ComputerName."
    }
}
