#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingComputerNameHardcoded', '',
    Justification = 'Test fixtures require hardcoded computer names as test inputs.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Mock stub functions declare params to match real signatures.')]
param()

BeforeAll {
    $script:ModuleRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    Get-ChildItem (Join-Path $script:ModuleRoot 'Classes') -Filter '*.ps1' | ForEach-Object { . $_.FullName }
    Get-ChildItem (Join-Path $script:ModuleRoot 'Private') -Filter '*.ps1' | ForEach-Object { . $_.FullName }
    Get-ChildItem (Join-Path $script:ModuleRoot 'Public')  -Filter '*.ps1' | ForEach-Object { . $_.FullName }

    # Stub for Get-WindowsOptionalFeature if not present on test machine
    if (-not (Get-Command Get-WindowsOptionalFeature -ErrorAction SilentlyContinue)) {
        function Get-WindowsOptionalFeature { param([switch]$Online, [string]$FeatureName) }
    }
}

Describe 'Get-DeviceComplianceStatus' {

    Context 'Returns exactly 5 items' {

        BeforeAll {
            Mock Get-ItemProperty { $null }
            Mock Test-Path { $false }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Home' } }
        }

        It 'Returns a list with exactly 5 compliance items' {
            $result = Get-DeviceComplianceStatus
            @($result).Count | Should -Be 5
        }

        It 'Each result object has Item, Status, Description properties' {
            $result = Get-DeviceComplianceStatus
            foreach ($item in $result) {
                $item.PSObject.Properties.Name | Should -Contain 'Item'
                $item.PSObject.Properties.Name | Should -Contain 'Status'
                $item.PSObject.Properties.Name | Should -Contain 'Description'
            }
        }

        It 'Item names match expected compliance check names' {
            $result = Get-DeviceComplianceStatus
            $names  = $result | ForEach-Object { $_.Item }
            $names | Should -Contain 'Location Services'
            $names | Should -Contain 'OneDrive'
            $names | Should -Contain 'Outlook External Images'
            $names | Should -Contain 'Windows Update Active Hours'
            $names | Should -Contain 'Unified Write Filter'
        }

        It 'Location Services is Non-Compliant when all registry reads return null' {
            # All mocks return null/false — svcCfg=null (not 1), consent=null (not Allow) — Non-Compliant.
            # Compliant requires: -not locked AND svcCfg==1 AND consent==Allow — all three must hold.
            $result  = Get-DeviceComplianceStatus
            $locSvc  = $result | Where-Object { $_.Item -eq 'Location Services' }
            $locSvc.Status | Should -Be 'Non-Compliant'
        }
    }

    Context 'Location Services — Compliant' {

        BeforeAll {
            # Single mock returns tailored data per path — no ParameterFilter needed.
            # This avoids ParameterFilter mock leakage in combined Pester multi-file runs.
            Mock Get-ItemProperty {
                $p = if ($PSBoundParameters.ContainsKey('Path')) { $PSBoundParameters['Path'] } else { $Path }
                if     ($p -like '*LocationAndSensors*') { [PSCustomObject]@{ DisableLocation = $null; DisableWindowsLocationProvider = $null; DisableSensors = $null } }
                elseif ($p -like '*lfsvc*')              { [PSCustomObject]@{ Status = 1 } }
                elseif ($p -like '*ConsentStore*')       { [PSCustomObject]@{ Value = 'Allow' } }
                else                                     { $null }
            }
            Mock Test-Path { $false }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Home' } }
        }

        It 'Location Services is Compliant when policy not locked, service enabled, consent Allow' {
            $result  = Get-DeviceComplianceStatus
            $locSvc  = $result | Where-Object { $_.Item -eq 'Location Services' }
            $locSvc.Status | Should -Be 'Compliant'
        }
    }

    Context 'OneDrive — Installed' {

        BeforeAll {
            Mock Get-ItemProperty { $null }
            Mock Test-Path { $true }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Home' } }
        }

        It 'OneDrive status is Installed when setup exe found' {
            $result = Get-DeviceComplianceStatus
            $od = $result | Where-Object { $_.Item -eq 'OneDrive' }
            $od.Status | Should -Be 'Installed'
        }
    }

    Context 'OneDrive — Not Installed' {

        BeforeAll {
            Mock Get-ItemProperty { $null }
            Mock Test-Path { $false }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Home' } }
        }

        It 'OneDrive status is Not Installed when setup exe not found' {
            $result = Get-DeviceComplianceStatus
            $od = $result | Where-Object { $_.Item -eq 'OneDrive' }
            $od.Status | Should -Be 'Not Installed'
        }
    }

    Context 'Outlook External Images — Not Configured' {

        BeforeAll {
            Mock Get-ItemProperty { [PSCustomObject]@{ BlockExtContent = $null } } -ParameterFilter { $Path -like '*Outlook*' }
            Mock Get-ItemProperty { $null }
            Mock Test-Path { $false }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Home' } }
        }

        It 'Status is Not Configured when BlockExtContent is null' {
            $result  = Get-DeviceComplianceStatus
            $outlook = $result | Where-Object { $_.Item -eq 'Outlook External Images' }
            $outlook.Status | Should -Be 'Not Configured'
        }
    }

    Context 'Outlook External Images — Compliant' {

        BeforeAll {
            Mock Get-ItemProperty { [PSCustomObject]@{ BlockExtContent = 0 } } -ParameterFilter { $Path -like '*Outlook*' }
            Mock Get-ItemProperty { $null }
            Mock Test-Path { $false }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Home' } }
        }

        It 'Status is Compliant when BlockExtContent is 0' {
            $result  = Get-DeviceComplianceStatus
            $outlook = $result | Where-Object { $_.Item -eq 'Outlook External Images' }
            $outlook.Status | Should -Be 'Compliant'
        }
    }

    Context 'Outlook External Images — Blocked' {

        BeforeAll {
            Mock Get-ItemProperty { [PSCustomObject]@{ BlockExtContent = 1 } } -ParameterFilter { $Path -like '*Outlook*' }
            Mock Get-ItemProperty { $null }
            Mock Test-Path { $false }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Home' } }
        }

        It 'Status is Blocked when BlockExtContent is 1' {
            $result  = Get-DeviceComplianceStatus
            $outlook = $result | Where-Object { $_.Item -eq 'Outlook External Images' }
            $outlook.Status | Should -Be 'Blocked'
        }
    }

    Context 'Windows Update Active Hours — Configured' {

        BeforeAll {
            Mock Get-ItemProperty { [PSCustomObject]@{ ActiveHoursStart = 8; ActiveHoursEnd = 18 } } -ParameterFilter { $Path -like '*WindowsUpdate*' }
            Mock Get-ItemProperty { $null }
            Mock Test-Path { $false }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Home' } }
        }

        It 'Status is Configured when ActiveHoursStart and ActiveHoursEnd are present' {
            $result = Get-DeviceComplianceStatus
            $wu = $result | Where-Object { $_.Item -eq 'Windows Update Active Hours' }
            $wu.Status | Should -Be 'Configured'
        }
    }

    Context 'Windows Update Active Hours — Not Configured' {

        BeforeAll {
            Mock Get-ItemProperty { [PSCustomObject]@{ ActiveHoursStart = $null; ActiveHoursEnd = $null } } -ParameterFilter { $Path -like '*WindowsUpdate*' }
            Mock Get-ItemProperty { $null }
            Mock Test-Path { $false }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Home' } }
        }

        It 'Status is Not Configured when active hours values are null' {
            $result = Get-DeviceComplianceStatus
            $wu = $result | Where-Object { $_.Item -eq 'Windows Update Active Hours' }
            $wu.Status | Should -Be 'Not Configured'
        }
    }

    Context 'UWF — non-Enterprise OS' {

        BeforeAll {
            Mock Get-ItemProperty { $null }
            Mock Test-Path { $false }
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' } {
                [PSCustomObject]@{ Caption = 'Windows 10 Pro' }
            }
        }

        It 'UWF status is N/A on non-Enterprise OS' {
            $result = Get-DeviceComplianceStatus
            $uwf = $result | Where-Object { $_.Item -eq 'Unified Write Filter' }
            $uwf.Status | Should -Be 'N/A'
        }
    }

    Context 'Error handling — exception in a check' {

        BeforeAll {
            # Throw on Location Services policy path only; let other paths return null
            Mock Get-ItemProperty { throw 'Registry access denied' } -ParameterFilter { $Path -like '*LocationAndSensors*' }
            Mock Get-ItemProperty { $null }
            Mock Test-Path { $false }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Home' } }
        }

        It 'Location Services returns Error status when registry access throws' {
            $result  = Get-DeviceComplianceStatus
            $locSvc  = $result | Where-Object { $_.Item -eq 'Location Services' }
            $locSvc.Status | Should -Be 'Error'
        }

        It 'Function still returns 5 items even when one check throws' {
            $result = Get-DeviceComplianceStatus
            @($result).Count | Should -Be 5
        }
    }
}
