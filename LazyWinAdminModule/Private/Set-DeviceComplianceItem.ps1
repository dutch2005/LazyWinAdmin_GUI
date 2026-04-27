function Set-DeviceComplianceItem {
    <#
    .SYNOPSIS
        Remediates a local device compliance item.
    .DESCRIPTION
        Supported items:
          LocationServices       — clears policy blocks, sets consent to Allow,
                                   restarts lfsvc (requires Administrator).
          OutlookExternalImages  — sets BlockExtContent = 0 in HKCU (no admin needed).
          WindowsUpdateActiveHours — sets ActiveHoursStart/End in HKLM (requires Administrator).
          RemoveOneDrive         — uninstalls OneDrive, cleans registry and files
                                   (requires Administrator).
    .PARAMETER Item
        The compliance item to remediate.
    .PARAMETER ActiveHoursStart
        Start of Windows Update active hours, 0–23 (default 8). Used only with
        WindowsUpdateActiveHours.
    .PARAMETER ActiveHoursEnd
        End of Windows Update active hours, 0–23 (default 18). Used only with
        WindowsUpdateActiveHours.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('LocationServices', 'OutlookExternalImages', 'WindowsUpdateActiveHours', 'RemoveOneDrive')]
        [string]$Item,

        [ValidateRange(0, 23)]
        [int]$ActiveHoursStart = 8,

        [ValidateRange(0, 23)]
        [int]$ActiveHoursEnd = 18
    )

    if (-not $PSCmdlet.ShouldProcess($Item, "Set compliance item")) {
        return "[!] Skipped by -WhatIf or -Confirm."
    }

    try {
        switch ($Item) {

            'LocationServices' {
                $policyPath  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors'
                $svcCfgPath  = 'HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration'
                $consentPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'

                if (-not (Test-Path $policyPath)) { New-Item -Path $policyPath -Force | Out-Null }
                foreach ($flag in @('DisableLocation', 'DisableWindowsLocationProvider', 'DisableSensors')) {
                    Set-ItemProperty -Path $policyPath -Name $flag -Value 0 -Type DWord -Force
                }

                if (-not (Test-Path $svcCfgPath)) { New-Item -Path $svcCfgPath -Force | Out-Null }
                Set-ItemProperty -Path $svcCfgPath -Name 'Status' -Value 1 -Type DWord -Force

                if (-not (Test-Path $consentPath)) { New-Item -Path $consentPath -Force | Out-Null }
                Set-ItemProperty -Path $consentPath -Name 'Value' -Value 'Allow' -Type String -Force

                # Set Allow for all currently loaded user hives
                Get-ChildItem Registry::HKEY_USERS |
                    Where-Object { $_.Name -match 'S-1-5-21-\d+-\d+-\d+-\d+$' } |
                    ForEach-Object {
                        $userConsent = "Registry::HKEY_USERS\$($_.PSChildName)\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
                        if (-not (Test-Path $userConsent)) { New-Item -Path $userConsent -Force | Out-Null }
                        Set-ItemProperty -Path $userConsent -Name 'Value' -Value 'Allow' -Type String -Force
                    }

                $serviceRestarted = $true
                try {
                    Restart-Service -Name 'lfsvc' -Force -ErrorAction Stop
                }
                catch {
                    $serviceRestarted = $false
                    Write-Verbose "Set-DeviceComplianceItem: lfsvc restart failed: $_"
                }

                if ($serviceRestarted) {
                    return "[OK] Location Services enabled and consent set to Allow"
                }
                return "[!] Registry updated, but 'lfsvc' service restart failed. Reboot or restart the service manually to apply."
            }

            'OutlookExternalImages' {
                $regPath = 'HKCU:\Software\Microsoft\Office\16.0\Outlook\Options\Mail'
                if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
                Set-ItemProperty -Path $regPath -Name 'BlockExtContent' -Value 0 -Type DWord -Force
                return "[OK] Outlook external image download enabled (BlockExtContent = 0)"
            }

            'WindowsUpdateActiveHours' {
                if ($ActiveHoursStart -eq $ActiveHoursEnd) {
                    return "[!] Active hours start and end cannot be the same value."
                }
                $regPath = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
                if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
                Set-ItemProperty -Path $regPath -Name 'ActiveHoursStart' -Value $ActiveHoursStart -Type DWord -Force
                Set-ItemProperty -Path $regPath -Name 'ActiveHoursEnd'   -Value $ActiveHoursEnd   -Type DWord -Force
                return "[OK] Windows Update active hours set to $($ActiveHoursStart):00 - $($ActiveHoursEnd):00"
            }

            'RemoveOneDrive' {
                Get-Process -Name OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

                foreach ($setup in @(
                    "$env:SystemRoot\System32\OneDriveSetup.exe",
                    "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
                )) {
                    if (Test-Path $setup) {
                        Start-Process -FilePath $setup -ArgumentList '/uninstall' -NoNewWindow -Wait -ErrorAction SilentlyContinue
                    }
                }

                # File cleanup
                Remove-Item -Path "$env:LocalAppData\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "$env:AppData\Microsoft\OneDrive"      -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "$env:ProgramData\Microsoft OneDrive"  -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "C:\OneDriveTemp"                      -Recurse -Force -ErrorAction SilentlyContinue

                # Registry cleanup
                Remove-Item -Path 'HKCU:\Software\Microsoft\OneDrive'              -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\OneDrive'              -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\OneDrive'  -Recurse -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' `
                    -Name 'OneDrive' -ErrorAction SilentlyContinue

                return "[OK] OneDrive removed and cleanup complete"
            }
        }
    }
    catch {
        Write-Warning "Compliance remediation failed for '$Item': $_"
        return "[!] Remediation failed for '$Item'. Some steps may require Administrator rights."
    }
}
