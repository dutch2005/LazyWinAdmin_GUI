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
        $policyReg = Get-ItemProperty -Path $policyPath -ErrorAction SilentlyContinue
        foreach ($flag in @('DisableLocation', 'DisableWindowsLocationProvider', 'DisableSensors')) {
            $v = if ($null -ne $policyReg) { $policyReg.$flag } else { $null }
            if (($v -as [int]) -eq 1) { $policyLocked = $true }
        }
        $svcReg  = Get-ItemProperty -Path $svcCfgPath  -ErrorAction SilentlyContinue
        $svcCfg  = if ($null -ne $svcReg)  { $svcReg.Status } else { $null }
        $cstReg  = Get-ItemProperty -Path $consentPath  -ErrorAction SilentlyContinue
        $consent = if ($null -ne $cstReg)  { $cstReg.Value  } else { $null }

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
        $regPath  = 'HKCU:\Software\Microsoft\Office\16.0\Outlook\Options\Mail'
        $outlReg  = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
        $v        = if ($null -ne $outlReg) { $outlReg.BlockExtContent } else { $null }
        $status   = if ($null -eq $v) { 'Not Configured' } elseif ($v -eq 0) { 'Compliant' } else { 'Blocked' }
        $detail   = "BlockExtContent = $(if ($null -eq $v) { '(not set)' } else { $v })"
    }
    catch {
        $status = 'Error'; $detail = "Could not read Outlook registry key."
    }
    $results.Add([PSCustomObject]@{ Item = 'Outlook External Images'; Status = $status; Description = $detail })

    # 4. Windows Update active hours
    try {
        $regPath = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
        $reg     = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
        $start   = if ($null -ne $reg) { $reg.ActiveHoursStart } else { $null }
        $end     = if ($null -ne $reg) { $reg.ActiveHoursEnd   } else { $null }
        $status  = if ($null -ne $start -and $null -ne $end) { 'Configured' } else { 'Not Configured' }
        $detail  = if ($null -ne $start) { "Active hours: $($start):00 to $($end):00" } else { 'Active hours not set' }
    }
    catch {
        $status = 'Error'; $detail = "Could not read Windows Update registry key."
    }
    $results.Add([PSCustomObject]@{ Item = 'Windows Update Active Hours'; Status = $status; Description = $detail })

    # 5. Unified Write Filter (Enterprise only)
    try {
        $osInfo    = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
        $osCaption = if ($null -ne $osInfo) { $osInfo.Caption } else { '' }
        if ($osCaption -like '*Enterprise*') {
            $feature     = Get-WindowsOptionalFeature -Online -FeatureName 'Client-UnifiedWriteFilter' -ErrorAction SilentlyContinue
            $featureState = if ($null -ne $feature) { $feature.State } else { $null }
            if ($featureState -eq 'Enabled') {
                $uwf        = Get-CimInstance -Namespace 'root\standardcimv2\embedded' -ClassName 'UWF_Filter' -ErrorAction SilentlyContinue
                $uwfEnabled = if ($null -ne $uwf) { $uwf.CurrentEnabled } else { $null }
                $status     = if ($null -eq $uwfEnabled) { 'Error' } elseif ($uwfEnabled) { 'Enabled' } else { 'Disabled' }
                $detail     = "UWF feature installed; CurrentEnabled = $(if ($null -eq $uwfEnabled) { 'Unknown' } else { $uwfEnabled })"
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
