function Start-LWAQuickAssist {
    <#
    .SYNOPSIS
        Launches the Windows Quick Assist application.
    #>
    [CmdletBinding()]
    param ()
    process {
        Start-Process -FilePath "quickassist.exe" -ErrorAction Stop
        return "[OK] Quick Assist launched."
    }
}
