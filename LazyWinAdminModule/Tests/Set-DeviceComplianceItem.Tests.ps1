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
}

Describe 'Set-DeviceComplianceItem' {

    Context 'Parameter validation' {

        It 'Item parameter is mandatory — throws without it' {
            { Set-DeviceComplianceItem } | Should -Throw
        }

        It 'Invalid Item value throws (ValidateSet enforcement)' {
            { Set-DeviceComplianceItem -Item 'InvalidItem' } | Should -Throw
        }
    }

    Context 'WhatIf support' {

        It 'Returns "[!] Skipped by -WhatIf or -Confirm." when -WhatIf is specified' {
            $result = Set-DeviceComplianceItem -Item 'OutlookExternalImages' -WhatIf
            $result | Should -Be '[!] Skipped by -WhatIf or -Confirm.'
        }
    }

    Context 'OutlookExternalImages remediation' {

        BeforeAll {
            Mock Test-Path { $true }
            Mock New-Item { }
            Mock Set-ItemProperty { }
            Mock Get-ChildItem { @() }
        }

        It 'Returns [OK] message confirming Outlook setting was applied' {
            $result = Set-DeviceComplianceItem -Item 'OutlookExternalImages'
            $result | Should -Match '\[OK\]'
            $result | Should -BeLike '*Outlook external image*'
        }

        It 'Calls Set-ItemProperty to write BlockExtContent = 0' {
            Set-DeviceComplianceItem -Item 'OutlookExternalImages' | Out-Null
            Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'BlockExtContent' -and $Value -eq 0
            }
        }
    }

    Context 'OutlookExternalImages — path does not exist (creates it)' {

        BeforeAll {
            Mock Test-Path { $false }
            Mock New-Item { }
            Mock Set-ItemProperty { }
            Mock Get-ChildItem { @() }
        }

        It 'Creates the registry path when it does not exist' {
            Set-DeviceComplianceItem -Item 'OutlookExternalImages' | Out-Null
            Should -Invoke New-Item -Times 1 -Exactly
        }
    }

    Context 'WindowsUpdateActiveHours — same start and end' {

        It 'Returns [!] message when start equals end' {
            $result = Set-DeviceComplianceItem -Item 'WindowsUpdateActiveHours' -ActiveHoursStart 8 -ActiveHoursEnd 8
            $result | Should -Be '[!] Active hours start and end cannot be the same value.'
        }
    }

    Context 'WindowsUpdateActiveHours — valid values' {

        BeforeAll {
            Mock Test-Path { $true }
            Mock New-Item { }
            Mock Set-ItemProperty { }
        }

        It 'Returns [OK] message with hours when start and end differ' {
            $result = Set-DeviceComplianceItem -Item 'WindowsUpdateActiveHours' -ActiveHoursStart 8 -ActiveHoursEnd 18
            $result | Should -Match '\[OK\]'
            $result | Should -BeLike '*8:00 - 18:00*'
        }
    }

    Context 'LocationServices remediation' {

        BeforeAll {
            Mock Test-Path { $true }
            Mock New-Item { }
            Mock Set-ItemProperty { }
            Mock Get-ChildItem { @() }
            Mock Restart-Service { }
        }

        It 'Returns [OK] message confirming Location Services was enabled' {
            $result = Set-DeviceComplianceItem -Item 'LocationServices'
            $result | Should -Match '\[OK\]'
            $result | Should -BeLike '*Location Services*'
            Should -Invoke Restart-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'lfsvc' }
        }
    }

    Context 'LocationServices remediation — lfsvc restart fails' {

        BeforeAll {
            Mock Test-Path { $true }
            Mock New-Item { }
            Mock Set-ItemProperty { }
            Mock Get-ChildItem { @() }
            Mock Restart-Service { throw 'Access denied' }
        }

        It 'Returns [!] partial-success message when lfsvc restart throws (registry applied, restart failed)' {
            $result = Set-DeviceComplianceItem -Item 'LocationServices'
            $result | Should -Match '\[!\]'
            $result | Should -BeLike '*Registry updated*'
            $result | Should -BeLike "*lfsvc*"
        }
    }

    Context 'RemoveOneDrive remediation' {

        BeforeAll {
            Mock Get-Process { $null }
            Mock Stop-Process { }
            Mock Test-Path { $false }
            Mock Start-Process { }
            Mock Remove-Item { }
            Mock Remove-ItemProperty { }
        }

        It 'Returns [OK] message confirming OneDrive removal' {
            $result = Set-DeviceComplianceItem -Item 'RemoveOneDrive'
            $result | Should -Be '[OK] OneDrive removed and cleanup complete'
        }
    }

    Context 'Error path' {

        BeforeAll {
            Mock Test-Path { $true }
            Mock Set-ItemProperty { throw 'Access is denied' }
        }

        It 'Returns [!] Remediation failed message when Set-ItemProperty throws' {
            $result = Set-DeviceComplianceItem -Item 'OutlookExternalImages'
            $result | Should -Match '\[!\]'
            $result | Should -BeLike '*Remediation failed*'
        }
    }
}