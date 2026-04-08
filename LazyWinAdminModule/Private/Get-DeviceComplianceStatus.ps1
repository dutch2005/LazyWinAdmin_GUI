function Get-DeviceComplianceStatus {
    <#
    .SYNOPSIS
        Checks local device compliance items and returns a status list.
    .DESCRIPTION
        Checks: Location Services policy/consent, OneDrive installation,
        Outlook external image download setting, Windows Update active hours,
        and Unified Write Filter state (Enterprise only).
        All checks are registry/WMI reads — no network required.
    #>
    [CmdletBinding()]
    param ()

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    # 1. Location Services
    try {
        $policyPath  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors'
        $svcCfgPath  = 'HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration'
        $consentPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'

        $policyLocked = $false
        foreach ($flag in @('DisableLocation', 'DisableWindowsLocationProvider', 'DisableSensors')) {
            $v = (Get-ItemProperty -Path $policyPath -ErrorAction SilentlyContinue).$flag
            if (($v -as [int]) -eq 1) { $policyLocked = $true }
        }
        $svcCfg  = (Get-ItemProperty -Path $svcCfgPath  -ErrorAction SilentlyContinue).Status
        $consent = (Get-ItemProperty -Path $consentPath  -ErrorAction SilentlyContinue).Value

        $status = if (-not $policyLocked -and ($svcCfg -as [int]) -eq 1 -and $consent -match '^(?i)Allow$') {
            'Compliant'
        } else {
            'Non-Compliant'
        }
        $detail = "Policy blocked: $policyLocked | Service cfg: $svcCfg | Consent: $consent"
    }
    catch {
        $status = 'Error'; $detail = "Could not read location registry keys."
    }
    $results.Add([PSCustomObject]@{ Item = 'Location Services'; Status = $status; Description = $detail })

    # 2. OneDrive
    try {
        $installed = (Test-Path "$env:SystemRoot\System32\OneDriveSetup.exe") -or
                     (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe")
        $status = if ($installed) { 'Installed' } else { 'Not Installed' }
        $detail = if ($installed) { 'OneDrive setup executable found on disk' } else { 'OneDrive setup executable not found' }
    }
    catch {
        $status = 'Error'; $detail = "Could not check OneDrive installation."
    }
    $results.Add([PSCustomObject]@{ Item = 'OneDrive'; Status = $status; Description = $detail })

    # 3. Outlook external image auto-download
    try {
        $regPath = 'HKCU:\Software\Microsoft\Office\16.0\Outlook\Options\Mail'
        $v       = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).BlockExtContent
        $status  = if ($null -eq $v) { 'Not Configured' } elseif ($v -eq 0) { 'Compliant' } else { 'Blocked' }
        $detail  = "BlockExtContent = $(if ($null -eq $v) { '(not set)' } else { $v })"
    }
    catch {
        $status = 'Error'; $detail = "Could not read Outlook registry key."
    }
    $results.Add([PSCustomObject]@{ Item = 'Outlook External Images'; Status = $status; Description = $detail })

    # 4. Windows Update active hours
    try {
        $regPath = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
        $reg     = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
        $start   = $reg.ActiveHoursStart
        $end     = $reg.ActiveHoursEnd
        $status  = if ($null -ne $start -and $null -ne $end) { 'Configured' } else { 'Not Configured' }
        $detail  = if ($null -ne $start) { "Active hours: $($start):00 to $($end):00" } else { 'Active hours not set' }
    }
    catch {
        $status = 'Error'; $detail = "Could not read Windows Update registry key."
    }
    $results.Add([PSCustomObject]@{ Item = 'Windows Update Active Hours'; Status = $status; Description = $detail })

    # 5. Unified Write Filter (Enterprise only)
    try {
        $osCaption = (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption
        if ($osCaption -like '*Enterprise*') {
            $feature = Get-WindowsOptionalFeature -Online -FeatureName 'Client-UnifiedWriteFilter' -ErrorAction SilentlyContinue
            if ($feature.State -eq 'Enabled') {
                $uwf    = Get-WmiObject -Namespace 'root\standardcimv2\embedded' -Class 'UWF_Filter' -ErrorAction SilentlyContinue
                $status = if ($uwf.CurrentEnabled) { 'Enabled' } else { 'Disabled' }
                $detail = 'UWF feature installed; CurrentEnabled = ' + $uwf.CurrentEnabled
            }
            else {
                $status = 'Feature Not Installed'
                $detail = 'Windows Enterprise detected but UWF optional feature is not enabled'
            }
        }
        else {
            $status = 'N/A'
            $detail = 'Unified Write Filter requires Windows Enterprise'
        }
    }
    catch {
        $status = 'Error'; $detail = "Could not check UWF state."
    }
    $results.Add([PSCustomObject]@{ Item = 'Unified Write Filter'; Status = $status; Description = $detail })

    return $results
}
