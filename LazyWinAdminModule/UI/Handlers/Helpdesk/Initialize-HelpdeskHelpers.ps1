# Shared helpers for the Helpdesk Quick Actions UI.
# Dot-sourced into Start-LazyWinAdmin scope.

function Write-HelpdeskOutput {
    param([Parameter(Mandatory)][string]$Message)

    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $txtHelpdeskOutput.Text = "[$timestamp] $Message`r`n" + $txtHelpdeskOutput.Text
}

function Get-HelpdeskTarget {
    param([Parameter(Mandatory)][string]$Prompt)

    $target = $txtHelpdeskTarget.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($target)) {
        Write-HelpdeskOutput "[!] $Prompt"
        return $null
    }

    return $target
}

function Invoke-HelpdeskUiAction {
    param(
        [Parameter(Mandatory)][string]$Activity,
        [Parameter(Mandatory)][scriptblock]$Action
    )

    Write-HelpdeskOutput $Activity
    try {
        $result = & $Action
        if ($null -ne $result) {
            $text = ($result | Out-String).TrimEnd()
            if ($text) { Write-HelpdeskOutput $text }
        }
    }
    catch {
        Write-Verbose "Helpdesk action failed: $($_.Exception.Message)"
        Write-HelpdeskOutput '[!] Action failed. Review the application log for details.'
    }
}
