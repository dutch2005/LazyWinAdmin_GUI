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

Describe 'Get-ComputerRegistryValue' {

    Context 'Parameter validation' {

        It 'ComputerName is mandatory — throws without it' {
            { Get-ComputerRegistryValue -Hive 'HKLM' -KeyPath 'SOFTWARE\Test' } | Should -Throw
        }

        It 'Hive is mandatory — throws without it' {
            { Get-ComputerRegistryValue -ComputerName 'localhost' -KeyPath 'SOFTWARE\Test' } | Should -Throw
        }

        It 'KeyPath is mandatory — throws without it' {
            { Get-ComputerRegistryValue -ComputerName 'localhost' -Hive 'HKLM' } | Should -Throw
        }

        It 'Invalid Hive value throws (ValidateSet enforcement)' {
            { Get-ComputerRegistryValue -ComputerName 'localhost' -Hive 'HKFAKE' -KeyPath 'SOFTWARE\Test' } | Should -Throw
        }
    }

    Context 'Successful value retrieval' {

        BeforeAll {
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'GetStringValue' } {
                [PSCustomObject]@{ ReturnValue = 0; sValue = 'ExpectedValue' }
            }
        }

        It 'Returns sValue when GetStringValue returns 0' {
            $result = Get-ComputerRegistryValue -ComputerName 'localhost' -Hive 'HKLM' -KeyPath 'SOFTWARE\Test' -ValueName 'MyValue'
            $result | Should -Be 'ExpectedValue'
        }
    }

    Context 'Non-zero return value' {

        BeforeAll {
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'GetStringValue' } {
                [PSCustomObject]@{ ReturnValue = 2; sValue = $null }
            }
        }

        It 'Returns $null when GetStringValue returns non-zero (value not found)' {
            $result = Get-ComputerRegistryValue -ComputerName 'localhost' -Hive 'HKLM' -KeyPath 'SOFTWARE\Test' -ValueName 'Missing'
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'CIM exception' {

        BeforeAll {
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'GetStringValue' } {
                throw 'WinRM connection refused'
            }
        }

        It 'Returns $null when Invoke-CimMethod throws' {
            $result = Get-ComputerRegistryValue -ComputerName 'unreachable-host' -Hive 'HKLM' -KeyPath 'SOFTWARE\Test' -ValueName 'v'
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Hive mapping' {

        BeforeAll {
            $script:CapturedCimArgs = $null
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'GetStringValue' } {
                $script:CapturedCimArgs = $Arguments
                [PSCustomObject]@{ ReturnValue = 0; sValue = 'v' }
            }
        }

        It 'HKLM maps to 2147483650' {
            $script:CapturedCimArgs = $null
            Get-ComputerRegistryValue -ComputerName 'localhost' -Hive 'HKLM' -KeyPath 'SOFTWARE\Test' -ValueName 'v' | Out-Null
            $script:CapturedCimArgs.hDefKey | Should -Be 2147483650
        }

        It 'HKCU maps to 2147483649' {
            $script:CapturedCimArgs = $null
            Get-ComputerRegistryValue -ComputerName 'localhost' -Hive 'HKCU' -KeyPath 'SOFTWARE\Test' -ValueName 'v' | Out-Null
            $script:CapturedCimArgs.hDefKey | Should -Be 2147483649
        }

        It 'HKU maps to 2147483651' {
            $script:CapturedCimArgs = $null
            Get-ComputerRegistryValue -ComputerName 'localhost' -Hive 'HKU' -KeyPath 'S-1-5-21' -ValueName 'v' | Out-Null
            $script:CapturedCimArgs.hDefKey | Should -Be 2147483651
        }

        It 'HKCR maps to 2147483648' {
            $script:CapturedCimArgs = $null
            Get-ComputerRegistryValue -ComputerName 'localhost' -Hive 'HKCR' -KeyPath '.txt' -ValueName 'v' | Out-Null
            $script:CapturedCimArgs.hDefKey | Should -Be 2147483648
        }

        It 'HKCC maps to 2147483652' {
            $script:CapturedCimArgs = $null
            Get-ComputerRegistryValue -ComputerName 'localhost' -Hive 'HKCC' -KeyPath 'System' -ValueName 'v' | Out-Null
            $script:CapturedCimArgs.hDefKey | Should -Be 2147483652
        }
    }

    Context 'Invoke-CimMethod receives correct arguments' {

        It 'Calls Invoke-CimMethod with MethodName GetStringValue' {
            Mock Invoke-CimMethod { [PSCustomObject]@{ ReturnValue = 0; sValue = 'val' } }
            Get-ComputerRegistryValue -ComputerName 'localhost' -Hive 'HKLM' -KeyPath 'SOFTWARE\Test' -ValueName 'v' | Out-Null
            Should -Invoke Invoke-CimMethod -Times 1 -Exactly -ParameterFilter { $MethodName -eq 'GetStringValue' }
        }
    }
}