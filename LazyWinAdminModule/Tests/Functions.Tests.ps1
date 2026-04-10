#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
<#
.SYNOPSIS
    Comprehensive function tests for the LazyWinAdmin module private functions.
    Pester v5 syntax only. All mocks match the actual internal implementation.

.NOTES
    CIM session functions (Get-ComputerHardware, Get-ComputerMotherboard,
    Get-ComputerNetwork, Set-ComputerRDP) cannot be mock-tested on success
    path unless WinRM is available locally, because -CimSession [CimSession[]]
    rejects a PSObject mock. Success-path tests are skipped when WinRM is
    unavailable ($script:WinRMAvailable = $false).

    IMPORTANT: $script:WinRMAvailable is probed at SCRIPT TOP LEVEL (outside
    BeforeAll) so that Pester's discovery phase — which evaluates -Skip:()
    parameters — can see the value. BeforeAll runs during execution phase,
    which is AFTER -Skip is evaluated.
#>

# ── WinRM probe runs at script/discovery time (before -Skip is evaluated) ────
$script:WinRMAvailable = $false
try {
    $probe = New-CimSession -ComputerName 'localhost' -ErrorAction Stop
    Remove-CimSession -CimSession $probe -ErrorAction SilentlyContinue
    $script:WinRMAvailable = $true
    Write-Host '[INFO] WinRM available on localhost — CimSession success-path tests will run.'
}
catch {
    Write-Host '[INFO] WinRM not available on localhost — CimSession success-path tests will be skipped.'
}
# ─────────────────────────────────────────────────────────────────────────────

BeforeAll {
    $script:ModuleRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

    # Dot-source in correct order: Classes → Private → Public
    Get-ChildItem (Join-Path $script:ModuleRoot 'Classes')  -Filter '*.ps1' |
        ForEach-Object { . $_.FullName }
    Get-ChildItem (Join-Path $script:ModuleRoot 'Private')  -Filter '*.ps1' |
        ForEach-Object { . $_.FullName }
    Get-ChildItem (Join-Path $script:ModuleRoot 'Public')   -Filter '*.ps1' |
        ForEach-Object { . $_.FullName }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'ApplicationState' {

    It 'Constructor creates a fully initialised instance' {
        $s = [LazyWinAdminState]::new()
        $s.SyncHash                | Should -Not -BeNull
        $s.RunspacePool            | Should -Not -BeNull
        # Wrap CimSessions in a boolean: piping an empty hashtable through the pipeline
        # yields zero items, which Pester treats as empty even with -Not -BeNull.
        ($null -ne $s.CimSessions) | Should -BeTrue
        $s.SyncHash.IsBusy         | Should -BeFalse
        $s.SyncHash.CloudConnected | Should -BeFalse
        $s.Dispose()
    }

    It 'Log adds a timestamped line' {
        $s = [LazyWinAdminState]::new()
        $s.Log('hello')
        $s.SyncHash.Logs.Count | Should -BeGreaterThan 0
        $s.SyncHash.Logs[-1]   | Should -Match 'hello'
        $s.Dispose()
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Get-ComputerService' {

    Context 'Happy path — services returned' {

        BeforeAll {
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_Service' } {
                [PSCustomObject]@{
                    Name        = 'Spooler'
                    DisplayName = 'Print Spooler'
                    State       = 'Running'
                    StartMode   = 'Auto'
                    StartName   = 'LocalSystem'
                    ProcessId   = 1234
                }
            }
        }

        It 'Returns a result object' {
            $result = Get-ComputerService -ComputerName 'localhost'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Result has expected property Name' {
            $result = Get-ComputerService -ComputerName 'localhost'
            ($result | Select-Object -First 1).Name | Should -Be 'Spooler'
        }

        It 'Result has expected properties (Name, DisplayName, State, StartMode, StartName, ProcessId)' {
            $result = Get-ComputerService -ComputerName 'localhost'
            $obj    = $result | Select-Object -First 1
            $obj.PSObject.Properties.Name | Should -Contain 'Name'
            $obj.PSObject.Properties.Name | Should -Contain 'DisplayName'
            $obj.PSObject.Properties.Name | Should -Contain 'State'
            $obj.PSObject.Properties.Name | Should -Contain 'StartMode'
            $obj.PSObject.Properties.Name | Should -Contain 'StartName'
            $obj.PSObject.Properties.Name | Should -Contain 'ProcessId'
        }

        It 'Calls Get-CimInstance with Win32_Service class' {
            Get-ComputerService -ComputerName 'localhost' | Out-Null
            Should -Invoke Get-CimInstance -Times 1 -Exactly -ParameterFilter { $ClassName -eq 'Win32_Service' }
        }
    }

    Context 'Name filter is applied' {

        BeforeAll {
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_Service' } {
                [PSCustomObject]@{
                    Name = 'wuauserv'; DisplayName = 'Windows Update'
                    State = 'Running'; StartMode = 'Manual'; StartName = 'LocalSystem'; ProcessId = 0
                }
            }
        }

        It 'Passes through a Name filter without error' {
            $result = Get-ComputerService -ComputerName 'localhost' -Name 'wuauserv'
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Error path' {

        BeforeAll {
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_Service' } {
                throw 'Simulated CIM failure'
            }
        }

        It 'Returns $null on CIM error' {
            $result = Get-ComputerService -ComputerName 'unreachable-host'
            $result | Should -BeNullOrEmpty
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Get-ComputerHardware' {

    Context 'Error path — always executed' {

        BeforeAll {
            Mock New-CimSession { throw 'Simulated CIM failure' }
        }

        It 'Returns $null when CimSession cannot be opened' {
            $result = Get-ComputerHardware -ComputerName 'unreachable-host'
            $result | Should -BeNullOrEmpty
        }

        It 'Does NOT call Remove-CimSession when session was never assigned' {
            # $CimSession is initialised to $null; if New-CimSession throws it stays $null
            # so the finally block should NOT call Remove-CimSession
            Mock Remove-CimSession { }
            Get-ComputerHardware -ComputerName 'unreachable-host' | Out-Null
            Should -Invoke Remove-CimSession -Times 0
        }
    }

    Context 'Success path — skipped when WinRM unavailable' -Skip:(-not $script:WinRMAvailable) {

        It 'Returns a result with expected shape from localhost' {
            $result = Get-ComputerHardware -ComputerName 'localhost'
            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain 'Model'
            $result.PSObject.Properties.Name | Should -Contain 'Manufacturer'
            $result.PSObject.Properties.Name | Should -Contain 'RAM_GB'
            $result.PSObject.Properties.Name | Should -Contain 'CPU'
            $result.PSObject.Properties.Name | Should -Contain 'OS'
            $result.PSObject.Properties.Name | Should -Contain 'OS_Version'
            $result.PSObject.Properties.Name | Should -Contain 'SerialNumber'
            $result.PSObject.Properties.Name | Should -Contain 'Disks'
        }

        It 'RAM_GB is a positive number' {
            $result = Get-ComputerHardware -ComputerName 'localhost'
            $result.RAM_GB | Should -BeGreaterThan 0
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Get-ComputerMotherboard' {

    Context 'Error path — always executed' {

        BeforeAll {
            Mock New-CimSession { throw 'Simulated CIM failure' }
        }

        It 'Returns $null when CimSession cannot be opened' {
            $result = Get-ComputerMotherboard -ComputerName 'unreachable-host'
            $result | Should -BeNullOrEmpty
        }

        It 'Does NOT call Remove-CimSession when session was never assigned' {
            Mock Remove-CimSession { }
            Get-ComputerMotherboard -ComputerName 'unreachable-host' | Out-Null
            Should -Invoke Remove-CimSession -Times 0
        }
    }

    Context 'Success path — skipped when WinRM unavailable' -Skip:(-not $script:WinRMAvailable) {

        It 'Returns a result with Product, Manufacturer, SerialNumber, Version from localhost' {
            $result = Get-ComputerMotherboard -ComputerName 'localhost'
            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain 'Product'
            $result.PSObject.Properties.Name | Should -Contain 'Manufacturer'
            $result.PSObject.Properties.Name | Should -Contain 'SerialNumber'
            $result.PSObject.Properties.Name | Should -Contain 'Version'
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Get-ComputerNetwork' {

    Context 'Error path — always executed' {

        BeforeAll {
            Mock New-CimSession { throw 'Simulated CIM failure' }
        }

        It 'Returns $null when CimSession cannot be opened' {
            $result = Get-ComputerNetwork -ComputerName 'unreachable-host'
            $result | Should -BeNullOrEmpty
        }

        It 'Does NOT call Remove-CimSession when session was never assigned' {
            Mock Remove-CimSession { }
            Get-ComputerNetwork -ComputerName 'unreachable-host' | Out-Null
            Should -Invoke Remove-CimSession -Times 0
        }
    }

    Context 'Success path — skipped when WinRM unavailable' -Skip:(-not $script:WinRMAvailable) {

        It 'Returns adapter objects from localhost' {
            $result = Get-ComputerNetwork -ComputerName 'localhost'
            # May legitimately return empty array on machines with no adapters — just verify no error
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Adapter objects have expected shape' {
            $result = Get-ComputerNetwork -ComputerName 'localhost'
            $first  = $result | Select-Object -First 1
            $first.PSObject.Properties.Name | Should -Contain 'Description'
            $first.PSObject.Properties.Name | Should -Contain 'IPAddress'
            $first.PSObject.Properties.Name | Should -Contain 'MACAddress'
            $first.PSObject.Properties.Name | Should -Contain 'DHCPEnabled'
        }

        It 'OnlyIPEnabled switch does not throw' {
            { Get-ComputerNetwork -ComputerName 'localhost' -OnlyIPEnabled } | Should -Not -Throw
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Get-ComputerSoftware' {

    It 'Does NOT use Win32_Product class' {
        # Security test: Win32_Product triggers an MSI consistency repair on every query.
        # The function comment mentions Win32_Product only to say it is NOT used.
        # Assert that Win32_Product is never passed as a -ClassName argument.
        $src = Get-Content -Path (Join-Path $script:ModuleRoot 'Private\Get-ComputerSoftware.ps1') -Raw
        $src | Should -Not -Match '(?i)-ClassName\s+[''"]?Win32_Product'
    }

    Context 'Happy path' {
        # [Microsoft.Management.Infrastructure.CimInstance]::new('StdRegProv') creates a
        # genuine [CimInstance] without touching WMI — it satisfies the [CimInstance] type
        # constraint on Invoke-CimMethod's -InputObject parameter in Pester's mock proxy,
        # while letting us control all method results via mocked Invoke-CimMethod.

        BeforeAll {
            $script:FakeCimSoftware = [Microsoft.Management.Infrastructure.CimInstance]::new('StdRegProv')
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'StdRegProv' } { $script:FakeCimSoftware }

            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'EnumKey' } {
                [PSCustomObject]@{ ReturnValue = 0; sNames = @('AppAlpha', 'AppBeta') }
            }
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'GetStringValue' -and $Arguments.sValueName -eq 'DisplayName' } {
                switch -Regex ($Arguments.sSubKeyName) {
                    'AppAlpha' { return [PSCustomObject]@{ ReturnValue = 0; sValue = 'Alpha Application' } }
                    'AppBeta'  { return [PSCustomObject]@{ ReturnValue = 0; sValue = 'Beta Application'  } }
                    default    { return [PSCustomObject]@{ ReturnValue = 1; sValue = $null               } }
                }
            }
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'GetStringValue' -and $Arguments.sValueName -eq 'DisplayVersion' } {
                [PSCustomObject]@{ ReturnValue = 0; sValue = '1.0.0' }
            }
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'GetStringValue' -and $Arguments.sValueName -eq 'Publisher' } {
                [PSCustomObject]@{ ReturnValue = 0; sValue = 'TestVendor' }
            }
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'GetStringValue' -and $Arguments.sValueName -eq 'InstallDate' } {
                [PSCustomObject]@{ ReturnValue = 0; sValue = '20240115' }
            }
        }

        It 'Returns a non-null list of software' {
            $result = Get-ComputerSoftware -ComputerName 'localhost'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Result objects have Name, Version, Vendor, InstallDate properties' {
            $result = Get-ComputerSoftware -ComputerName 'localhost'
            $first  = $result | Select-Object -First 1
            $first.PSObject.Properties.Name | Should -Contain 'Name'
            $first.PSObject.Properties.Name | Should -Contain 'Version'
            $first.PSObject.Properties.Name | Should -Contain 'Vendor'
            $first.PSObject.Properties.Name | Should -Contain 'InstallDate'
        }

        It 'Results are sorted by Name' {
            $result = Get-ComputerSoftware -ComputerName 'localhost'
            $names  = $result | ForEach-Object { $_.Name }
            $sorted = $names | Sort-Object
            $names | Should -Be $sorted
        }

        It 'InstallDate is parsed to yyyy-MM-dd format' {
            $result = Get-ComputerSoftware -ComputerName 'localhost'
            $result | ForEach-Object { $_.InstallDate | Should -Match '^\d{4}-\d{2}-\d{2}$' }
        }

        It 'Deduplicates across both registry hives — no duplicate names' {
            $result = Get-ComputerSoftware -ComputerName 'localhost'
            $names  = $result | ForEach-Object { $_.Name }
            ($names | Sort-Object -Unique).Count | Should -Be $names.Count
        }

        It 'Search filter returns only matching software' {
            $result = Get-ComputerSoftware -ComputerName 'localhost' -Search 'Alpha'
            $result | Should -Not -BeNullOrEmpty
            $result | ForEach-Object { $_.Name | Should -Match 'Alpha' }
        }
    }

    Context 'Error path' {

        BeforeAll {
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'StdRegProv' } {
                throw 'Simulated CIM failure'
            }
        }

        It 'Returns $null on CIM error' {
            $result = Get-ComputerSoftware -ComputerName 'unreachable-host'
            $result | Should -BeNullOrEmpty
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Get-ComputerUptime' {

    Context 'Happy path' {

        BeforeAll {
            $bootTime = (Get-Date).AddDays(-3).AddHours(-2).AddMinutes(-15)
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' } {
                [PSCustomObject]@{ LastBootUpTime = $bootTime }
            }
        }

        It 'Returns a non-empty uptime string' {
            $result = Get-ComputerUptime -ComputerName 'localhost'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Uptime string matches "D Days H Hours M Minutes S Seconds" format' {
            $result = Get-ComputerUptime -ComputerName 'localhost'
            $result | Should -Match '^\d+ Days \d+ Hours \d+ Minutes \d+ Seconds$'
        }

        It 'Days component is at least 3 (boot was ~3 days ago)' {
            $result = Get-ComputerUptime -ComputerName 'localhost'
            $days   = [int]($result -split ' ')[0]
            $days   | Should -BeGreaterThan 2
        }
    }

    Context 'Error path' {

        BeforeAll {
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' } {
                throw 'Simulated CIM failure'
            }
        }

        It 'Returns "Error" string on CIM failure' {
            $result = Get-ComputerUptime -ComputerName 'unreachable-host'
            $result | Should -Be 'Error'
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Get-ComputerLocalUser' {

    Context 'Happy path' {

        BeforeAll {
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_UserAccount' } {
                [PSCustomObject]@{
                    Name             = 'Administrator'
                    FullName         = ''
                    Disabled         = $false
                    Lockout          = $false
                    PasswordRequired = $true
                    PasswordExpires  = $false
                    SID              = 'S-1-5-21-0-0-0-500'
                    Status           = 'OK'
                }
            }
        }

        It 'Returns a non-null result' {
            $result = Get-ComputerLocalUser -ComputerName 'localhost'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Result has expected properties' {
            $result = Get-ComputerLocalUser -ComputerName 'localhost'
            $obj    = $result | Select-Object -First 1
            $obj.PSObject.Properties.Name | Should -Contain 'Name'
            $obj.PSObject.Properties.Name | Should -Contain 'FullName'
            $obj.PSObject.Properties.Name | Should -Contain 'Disabled'
            $obj.PSObject.Properties.Name | Should -Contain 'Lockout'
            $obj.PSObject.Properties.Name | Should -Contain 'PasswordRequired'
            $obj.PSObject.Properties.Name | Should -Contain 'PasswordExpires'
            $obj.PSObject.Properties.Name | Should -Contain 'SID'
            $obj.PSObject.Properties.Name | Should -Contain 'Status'
        }

        It 'Does NOT return a Password property (security: no password hash exposure)' {
            $result = Get-ComputerLocalUser -ComputerName 'localhost'
            $obj    = $result | Select-Object -First 1
            $obj.PSObject.Properties.Name | Should -Not -Contain 'Password'
        }

        It 'Calls Get-CimInstance with Win32_UserAccount class' {
            Get-ComputerLocalUser -ComputerName 'localhost' | Out-Null
            Should -Invoke Get-CimInstance -Times 1 -Exactly -ParameterFilter { $ClassName -eq 'Win32_UserAccount' }
        }
    }

    Context 'Error path' {

        BeforeAll {
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_UserAccount' } {
                throw 'Simulated CIM failure'
            }
        }

        It 'Returns $null on CIM error' {
            $result = Get-ComputerLocalUser -ComputerName 'unreachable-host'
            $result | Should -BeNullOrEmpty
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Get-ComputerLocalGroup' {

    Context 'Happy path' {

        BeforeAll {
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_Group' } {
                [PSCustomObject]@{
                    Name    = 'Administrators'
                    Caption = 'DESKTOP\Administrators'
                    SID     = 'S-1-5-32-544'
                    Status  = 'OK'
                }
            }
        }

        It 'Returns a non-null result' {
            $result = Get-ComputerLocalGroup -ComputerName 'localhost'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Result has expected properties (Name, Caption, SID, Status)' {
            $result = Get-ComputerLocalGroup -ComputerName 'localhost'
            $obj    = $result | Select-Object -First 1
            $obj.PSObject.Properties.Name | Should -Contain 'Name'
            $obj.PSObject.Properties.Name | Should -Contain 'Caption'
            $obj.PSObject.Properties.Name | Should -Contain 'SID'
            $obj.PSObject.Properties.Name | Should -Contain 'Status'
        }

        It 'Calls Get-CimInstance with Win32_Group class' {
            Get-ComputerLocalGroup -ComputerName 'localhost' | Out-Null
            Should -Invoke Get-CimInstance -Times 1 -Exactly -ParameterFilter { $ClassName -eq 'Win32_Group' }
        }
    }

    Context 'Error path' {

        BeforeAll {
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_Group' } {
                throw 'Simulated CIM failure'
            }
        }

        It 'Returns $null on CIM error' {
            $result = Get-ComputerLocalGroup -ComputerName 'unreachable-host'
            $result | Should -BeNullOrEmpty
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Invoke-ComputerRegistry' {

    Context 'Input validation — ValidateSet enforcement' {
        # These tests require no CIM — validation fires at PowerShell parameter binding.

        It 'Throws on an invalid Action value' {
            { Invoke-ComputerRegistry -Action 'BadAction' -ComputerName 'localhost' -Hive 'HKLM' -KeyPath 'Software\Test' } |
                Should -Throw
        }

        It 'Throws on an invalid Hive value' {
            { Invoke-ComputerRegistry -Action 'Get' -ComputerName 'localhost' -Hive 'HKFAKE' -KeyPath 'Software\Test' } |
                Should -Throw
        }
    }

    Context 'Set action — unsupported ValueType returns false without CIM call' {
        # Write-Warning + return $false executes BEFORE any Invoke-CimMethod call.
        # No CIM or WinRM required.

        It 'Returns $false for unimplemented ValueType Binary' {
            $result = Invoke-ComputerRegistry -Action 'Set' -ComputerName 'localhost' `
                        -Hive 'HKLM' -KeyPath 'SOFTWARE\Test' -ValueName 'Bin' `
                        -Value 0 -ValueType 'Binary'
            $result | Should -BeFalse
        }
    }

    Context 'Error path — CIM unavailable' {

        BeforeAll {
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'StdRegProv' } {
                throw 'Simulated CIM failure'
            }
        }

        It 'Returns $null on CIM error' {
            $result = Invoke-ComputerRegistry -Action 'Get' -ComputerName 'unreachable' `
                        -Hive 'HKLM' -KeyPath 'SOFTWARE\Test' -ValueName 'v'
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'All CIM-dependent paths' {
        # [CimInstance]::new('StdRegProv') produces a genuine [CimInstance] that satisfies
        # Pester's Invoke-CimMethod proxy type constraint on -InputObject, with no WMI call.

        BeforeAll {
            $script:CapturedArgs  = $null
            $script:FakeCimReg    = [Microsoft.Management.Infrastructure.CimInstance]::new('StdRegProv')
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'StdRegProv' } { $script:FakeCimReg }
        }

        It 'Get — returns string value when GetStringValue succeeds' {
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'GetStringValue' } {
                [PSCustomObject]@{ ReturnValue = 0; sValue = 'TestValue123' }
            }
            $result = Invoke-ComputerRegistry -Action 'Get' -ComputerName 'localhost' `
                        -Hive 'HKLM' -KeyPath 'SOFTWARE\Test' -ValueName 'MyValue'
            $result | Should -Be 'TestValue123'
        }

        It 'Get — falls back to GetDWORDValue when GetStringValue fails' {
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'GetStringValue' } {
                [PSCustomObject]@{ ReturnValue = 2; sValue = $null }
            }
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'GetDWORDValue' } {
                [PSCustomObject]@{ ReturnValue = 0; uValue = [uint32]42 }
            }
            $result = Invoke-ComputerRegistry -Action 'Get' -ComputerName 'localhost' `
                        -Hive 'HKLM' -KeyPath 'SOFTWARE\Test' -ValueName 'DwordVal'
            $result | Should -Be 42
        }

        It 'Get — returns $null when both string and DWORD lookups fail' {
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'GetStringValue' } {
                [PSCustomObject]@{ ReturnValue = 2; sValue = $null }
            }
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'GetDWORDValue' } {
                [PSCustomObject]@{ ReturnValue = 2; uValue = $null }
            }
            $result = Invoke-ComputerRegistry -Action 'Get' -ComputerName 'localhost' `
                        -Hive 'HKLM' -KeyPath 'SOFTWARE\Test' -ValueName 'Missing'
            $result | Should -BeNullOrEmpty
        }

        It 'Set String — returns $true on success' {
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'SetStringValue' } {
                [PSCustomObject]@{ ReturnValue = 0 }
            }
            $result = Invoke-ComputerRegistry -Action 'Set' -ComputerName 'localhost' `
                        -Hive 'HKLM' -KeyPath 'SOFTWARE\Test' -ValueName 'Str' `
                        -Value 'hello' -ValueType 'String'
            $result | Should -BeTrue
        }

        It 'Set DWord — returns $true on success' {
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'SetDWordValue' } {
                [PSCustomObject]@{ ReturnValue = 0 }
            }
            $result = Invoke-ComputerRegistry -Action 'Set' -ComputerName 'localhost' `
                        -Hive 'HKLM' -KeyPath 'SOFTWARE\Test' -ValueName 'Dw' `
                        -Value 1 -ValueType 'DWord'
            $result | Should -BeTrue
        }

        It 'New — CreateKey returns $true on success' {
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'CreateKey' } {
                [PSCustomObject]@{ ReturnValue = 0 }
            }
            $result = Invoke-ComputerRegistry -Action 'New' -ComputerName 'localhost' `
                        -Hive 'HKLM' -KeyPath 'SOFTWARE\PesterTestNewKey'
            $result | Should -BeTrue
        }

        It 'New — CreateKey returns $false when registry rejects it (non-zero ReturnValue)' {
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'CreateKey' } {
                [PSCustomObject]@{ ReturnValue = 5 }
            }
            $result = Invoke-ComputerRegistry -Action 'New' -ComputerName 'localhost' `
                        -Hive 'HKLM' -KeyPath 'SOFTWARE\PesterTestBadKey'
            $result | Should -BeFalse
        }

        It 'Remove — calls DeleteValue when ValueName is supplied' {
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'DeleteValue' } {
                [PSCustomObject]@{ ReturnValue = 0 }
            }
            $result = Invoke-ComputerRegistry -Action 'Remove' -ComputerName 'localhost' `
                        -Hive 'HKLM' -KeyPath 'SOFTWARE\Test' -ValueName 'OldVal'
            $result | Should -BeTrue
            Should -Invoke Invoke-CimMethod -Times 1 -Exactly -ParameterFilter { $MethodName -eq 'DeleteValue' }
        }

        It 'Remove — calls DeleteKey when no ValueName is supplied' {
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'DeleteKey' } {
                [PSCustomObject]@{ ReturnValue = 0 }
            }
            $result = Invoke-ComputerRegistry -Action 'Remove' -ComputerName 'localhost' `
                        -Hive 'HKLM' -KeyPath 'SOFTWARE\Test'
            $result | Should -BeTrue
            Should -Invoke Invoke-CimMethod -Times 1 -Exactly -ParameterFilter { $MethodName -eq 'DeleteKey' }
        }

        It 'Maps HKLM to UInt32 2147483650' {
            $script:CapturedArgs = $null
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'GetStringValue' } {
                $script:CapturedArgs = $Arguments; [PSCustomObject]@{ ReturnValue = 0; sValue = 'v' }
            }
            Invoke-ComputerRegistry -Action 'Get' -ComputerName 'localhost' `
                -Hive 'HKLM' -KeyPath 'SOFTWARE\Test' -ValueName 'v' | Out-Null
            $script:CapturedArgs.hDefKey | Should -Be ([UInt32]2147483650)
        }

        It 'Maps HKCU to UInt32 2147483649' {
            $script:CapturedArgs = $null
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'GetStringValue' } {
                $script:CapturedArgs = $Arguments; [PSCustomObject]@{ ReturnValue = 0; sValue = 'v' }
            }
            Invoke-ComputerRegistry -Action 'Get' -ComputerName 'localhost' `
                -Hive 'HKCU' -KeyPath 'SOFTWARE\Test' -ValueName 'v' | Out-Null
            $script:CapturedArgs.hDefKey | Should -Be ([UInt32]2147483649)
        }

        It 'Maps HKCR to UInt32 2147483648' {
            $script:CapturedArgs = $null
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'GetStringValue' } {
                $script:CapturedArgs = $Arguments; [PSCustomObject]@{ ReturnValue = 0; sValue = 'v' }
            }
            Invoke-ComputerRegistry -Action 'Get' -ComputerName 'localhost' `
                -Hive 'HKCR' -KeyPath '.txt' -ValueName 'v' | Out-Null
            $script:CapturedArgs.hDefKey | Should -Be ([UInt32]2147483648)
        }

        It 'Maps HKU to UInt32 2147483651' {
            $script:CapturedArgs = $null
            Mock Invoke-CimMethod -ParameterFilter { $MethodName -eq 'GetStringValue' } {
                $script:CapturedArgs = $Arguments; [PSCustomObject]@{ ReturnValue = 0; sValue = 'v' }
            }
            Invoke-ComputerRegistry -Action 'Get' -ComputerName 'localhost' `
                -Hive 'HKU' -KeyPath 'S-1-5-21' -ValueName 'v' | Out-Null
            $script:CapturedArgs.hDefKey | Should -Be ([UInt32]2147483651)
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Get-EntraIdentity' {

    Context 'Guard — not connected to Graph' {

        BeforeAll {
            Mock Get-MgContext { return $null }
        }

        It 'Returns $null when Get-MgContext returns null' {
            $result = Get-EntraIdentity -Type 'User'
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Guard — OData injection protection' {

        BeforeAll {
            Mock Get-MgContext { return [PSCustomObject]@{ TenantId = 'fake-tenant' } }
        }

        It 'Returns $null when Search contains disallowed characters' {
            $result = Get-EntraIdentity -Type 'User' -Search 'test<script>'
            $result | Should -BeNullOrEmpty
        }

        It 'Returns $null when Search contains a semicolon' {
            $result = Get-EntraIdentity -Type 'User' -Search 'test;DROP'
            $result | Should -BeNullOrEmpty
        }

        It 'Accepts alphanumeric and safe characters without rejection' {
            Mock Get-MgUser { @([PSCustomObject]@{ DisplayName = 'John Doe'; UserPrincipalName = 'j@t.com'; Id = '1'; Mail = 'j@t.com'; JobTitle = 'Dev' }) }
            $result = Get-EntraIdentity -Type 'User' -Search 'John Doe'
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'User type — no search' {

        BeforeAll {
            Mock Get-MgContext { return [PSCustomObject]@{ TenantId = 'fake-tenant' } }
            Mock Get-MgUser {
                @(
                    [PSCustomObject]@{ DisplayName = 'Alice'; UserPrincipalName = 'alice@test.com'; Id = 'u1'; Mail = 'alice@test.com'; JobTitle = 'Admin' }
                )
            }
        }

        It 'Returns user objects' {
            $result = Get-EntraIdentity -Type 'User'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'User objects have expected properties' {
            $result = Get-EntraIdentity -Type 'User'
            $obj    = $result | Select-Object -First 1
            $obj.PSObject.Properties.Name | Should -Contain 'DisplayName'
            $obj.PSObject.Properties.Name | Should -Contain 'UserPrincipalName'
            $obj.PSObject.Properties.Name | Should -Contain 'Id'
            $obj.PSObject.Properties.Name | Should -Contain 'Mail'
            $obj.PSObject.Properties.Name | Should -Contain 'JobTitle'
        }

        It 'Calls Get-MgUser' {
            Get-EntraIdentity -Type 'User' | Out-Null
            Should -Invoke Get-MgUser -Times 1 -Exactly
        }
    }

    Context 'Group type — with search' {

        BeforeAll {
            Mock Get-MgContext { return [PSCustomObject]@{ TenantId = 'fake-tenant' } }
            Mock Get-MgGroup {
                @(
                    [PSCustomObject]@{ DisplayName = 'IT Admins'; Id = 'g1'; Description = 'IT group'; GroupTypes = @() }
                )
            }
        }

        It 'Returns group objects when search is provided' {
            $result = Get-EntraIdentity -Type 'Group' -Search 'IT'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Group objects have expected properties' {
            $result = Get-EntraIdentity -Type 'Group' -Search 'IT'
            $obj    = $result | Select-Object -First 1
            $obj.PSObject.Properties.Name | Should -Contain 'DisplayName'
            $obj.PSObject.Properties.Name | Should -Contain 'Id'
            $obj.PSObject.Properties.Name | Should -Contain 'Description'
            $obj.PSObject.Properties.Name | Should -Contain 'GroupTypes'
        }
    }

    Context 'Error path' {

        BeforeAll {
            Mock Get-MgContext { return [PSCustomObject]@{ TenantId = 'fake-tenant' } }
            Mock Get-MgUser { throw 'Graph API failure' }
        }

        It 'Returns $null on Graph exception' {
            $result = Get-EntraIdentity -Type 'User'
            $result | Should -BeNullOrEmpty
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Get-IntuneDevice' {

    Context 'Guard — not connected to Graph' {

        BeforeAll {
            Mock Get-MgContext { return $null }
        }

        It 'Returns $null when not connected' {
            $result = Get-IntuneDevice
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Guard — OData injection protection' {

        BeforeAll {
            Mock Get-MgContext { return [PSCustomObject]@{ TenantId = 'fake-tenant' } }
        }

        It 'Returns $null for Search containing special chars' {
            $result = Get-IntuneDevice -Search 'bad"value'
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Happy path — no search' {

        BeforeAll {
            Mock Get-MgContext { return [PSCustomObject]@{ TenantId = 'fake-tenant' } }
            Mock Get-MgDeviceManagementManagedDevice {
                @(
                    [PSCustomObject]@{
                        DeviceName            = 'PC-001'
                        UserPrincipalName     = 'user@test.com'
                        ComplianceState       = 'compliant'
                        OperatingSystem       = 'Windows'
                        Model                 = 'Surface Pro'
                        SerialNumber          = 'SN12345'
                        JoinType              = 'azureADJoined'
                        ManagementState       = 'managed'
                        DeviceEnrollmentType  = 'windowsAutoEnrollment'
                    }
                )
            }
        }

        It 'Returns device objects' {
            $result = Get-IntuneDevice
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Device objects have all expected properties' {
            $result = Get-IntuneDevice
            $obj    = $result | Select-Object -First 1
            @('DeviceName','UserPrincipalName','ComplianceState','OperatingSystem',
              'Model','SerialNumber','JoinType','ManagementState','DeviceEnrollmentType') |
              ForEach-Object {
                $obj.PSObject.Properties.Name | Should -Contain $_
              }
        }
    }

    Context 'Error path' {

        BeforeAll {
            Mock Get-MgContext { return [PSCustomObject]@{ TenantId = 'fake-tenant' } }
            Mock Get-MgDeviceManagementManagedDevice { throw 'Graph API failure' }
        }

        It 'Returns $null on exception' {
            $result = Get-IntuneDevice
            $result | Should -BeNullOrEmpty
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Connect-ModernCloud' {

    Context 'Successful interactive connection' {

        BeforeAll {
            Mock Connect-MgGraph { }
            Mock Get-MgContext {
                [PSCustomObject]@{ TenantId = 'abc-tenant-id'; Account = 'admin@contoso.com' }
            }
        }

        It 'Returns [OK] string with TenantId and Account' {
            $result = Connect-ModernCloud -Interactive
            $result | Should -Match '^\[OK\] Connected to Tenant: '
            $result | Should -Match 'abc-tenant-id'
            $result | Should -Match 'admin@contoso.com'
        }

        It 'Does NOT return exception text in the result' {
            $result = Connect-ModernCloud -Interactive
            $result | Should -Not -Match 'Exception'
            $result | Should -Not -Match 'Error'
        }
    }

    Context 'Connection completed but context unavailable' {

        BeforeAll {
            Mock Connect-MgGraph { }
            Mock Get-MgContext { return $null }
        }

        It 'Returns [!] context-not-retrieved message' {
            $result = Connect-ModernCloud -Interactive
            $result | Should -Be '[!] Authentication completed but Graph context could not be retrieved.'
        }
    }

    Context 'Connection exception' {

        BeforeAll {
            Mock Connect-MgGraph { throw 'Network timeout' }
            Mock Get-MgContext { return $null }
        }

        It 'Returns generic [!] failure message — never surfaces exception text' {
            $result = Connect-ModernCloud -Interactive
            $result | Should -Be '[!] Connection failed. Verify credentials and network connectivity.'
        }

        It 'Return value does NOT contain exception detail' {
            $result = Connect-ModernCloud -Interactive
            $result | Should -Not -Match 'Network timeout'
            $result | Should -Not -Match 'Exception'
        }
    }

    Context 'Service principal path — credential fragment protection' {

        BeforeAll {
            Mock Connect-MgGraph { throw 'SP auth failed' }
            Mock Get-MgContext { return $null }
        }

        It 'Does NOT expose ClientId or ClientSecret in return value' {
            $secureSecret = ConvertTo-SecureString 'SuperSecretValue!' -AsPlainText -Force
            $result = Connect-ModernCloud -TenantId 'tid' -ClientId 'my-client-id' -ClientSecret $secureSecret
            $result | Should -Not -Match 'my-client-id'
            $result | Should -Not -Match 'SuperSecretValue'
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Get-AzureResourceSummary' {

    Context 'Guard — not connected to Azure' {

        BeforeAll {
            Mock Get-AzContext { return $null }
        }

        It 'Returns $null when not connected to Azure' {
            $result = Get-AzureResourceSummary
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Happy path' {

        BeforeAll {
            Mock Get-AzContext { return [PSCustomObject]@{ Subscription = 'sub-123' } }
            Mock Search-AzGraph {
                @(
                    [PSCustomObject]@{ ResourceType = 'microsoft.compute/virtualmachines'; Count = 10 }
                    [PSCustomObject]@{ ResourceType = 'microsoft.storage/storageaccounts';  Count = 5  }
                )
            }
        }

        It 'Returns resource summary objects' {
            $result = Get-AzureResourceSummary
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Result objects have Name and Count properties' {
            $result = Get-AzureResourceSummary
            $obj    = $result | Select-Object -First 1
            $obj.PSObject.Properties.Name | Should -Contain 'Name'
            $obj.PSObject.Properties.Name | Should -Contain 'Count'
        }

        It 'Name property is the ResourceType value' {
            $result = Get-AzureResourceSummary
            ($result | Where-Object { $_.Name -eq 'microsoft.compute/virtualmachines' }) | Should -Not -BeNullOrEmpty
        }

        It 'Does NOT call Get-AzResource (uses Search-AzGraph instead)' {
            Mock Get-AzResource { throw 'Should not be called' }
            Get-AzureResourceSummary | Out-Null
            Should -Invoke Get-AzResource -Times 0
        }

        It 'Calls Search-AzGraph exactly once' {
            Get-AzureResourceSummary | Out-Null
            Should -Invoke Search-AzGraph -Times 1 -Exactly
        }
    }

    Context 'Error path' {

        BeforeAll {
            Mock Get-AzContext  { return [PSCustomObject]@{ Subscription = 'sub-123' } }
            Mock Search-AzGraph { throw 'Azure Resource Graph error' }
        }

        It 'Returns $null on Search-AzGraph exception' {
            $result = Get-AzureResourceSummary
            $result | Should -BeNullOrEmpty
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Get-ComputerADInfo' {

    BeforeAll {
        # On machines without RSAT the AD cmdlets don't exist, so Pester's Mock would throw
        # CommandNotFoundException. Create lightweight stubs so all contexts can mock them.
        if (-not (Get-Command Get-ADComputer -ErrorAction SilentlyContinue)) {
            function Get-ADComputer { param([string]$Filter, [string[]]$Properties, [string]$LDAPFilter) }
        }
        if (-not (Get-Command Get-ADUser -ErrorAction SilentlyContinue)) {
            function Get-ADUser    { param([string]$Filter, [string[]]$Properties, [string]$LDAPFilter) }
        }
        if (-not (Get-Command Get-ADGroup -ErrorAction SilentlyContinue)) {
            function Get-ADGroup   { param([string]$Filter, [string[]]$Properties, [string]$LDAPFilter) }
        }
    }

    Context 'Guard — ActiveDirectory module not available' {

        BeforeAll {
            Mock Get-Module { return $null } -ParameterFilter { $Name -eq 'ActiveDirectory' -and $ListAvailable }
        }

        It 'Returns $null when AD module is not available' {
            $result = Get-ComputerADInfo -Type 'Computer'
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Guard — AdFilter injection protection' {

        BeforeAll {
            Mock Get-Module {
                [PSCustomObject]@{ Name = 'ActiveDirectory'; Version = '1.0.0.0' }
            } -ParameterFilter { $Name -eq 'ActiveDirectory' -and $ListAvailable }
            Mock Import-Module { }
        }

        It 'Returns $null when AdFilter contains disallowed characters' {
            $result = Get-ComputerADInfo -Type 'Computer' -AdFilter 'PC*; DROP'
            $result | Should -BeNullOrEmpty
        }

        It 'Accepts wildcards in AdFilter (asterisk is allowed)' {
            Mock Get-ADComputer {
                @([PSCustomObject]@{
                    Name = 'PC001'; DNSHostName = 'PC001.domain.local'
                    OperatingSystem = 'Windows 11'; OperatingSystemVersion = '10.0'
                    LastLogonDate = (Get-Date); Enabled = $true; Description = ''; DistinguishedName = 'CN=PC001,DC=domain,DC=local'
                })
            }
            $result = Get-ComputerADInfo -Type 'Computer' -AdFilter 'PC*'
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Computer type' {

        BeforeAll {
            Mock Get-Module {
                [PSCustomObject]@{ Name = 'ActiveDirectory'; Version = '1.0.0.0' }
            } -ParameterFilter { $Name -eq 'ActiveDirectory' -and $ListAvailable }
            Mock Import-Module { }
            Mock Get-ADComputer {
                @([PSCustomObject]@{
                    Name = 'SERVER01'; DNSHostName = 'SERVER01.domain.local'
                    OperatingSystem = 'Windows Server 2022'; OperatingSystemVersion = '10.0 (20348)'
                    LastLogonDate = (Get-Date).AddDays(-1); Enabled = $true
                    Description = 'File server'; DistinguishedName = 'CN=SERVER01,OU=Servers,DC=domain,DC=local'
                })
            }
        }

        It 'Returns computer objects' {
            $result = Get-ComputerADInfo -Type 'Computer'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Computer objects have expected properties' {
            $result = Get-ComputerADInfo -Type 'Computer'
            $obj    = $result | Select-Object -First 1
            @('Name','DNSHostName','OperatingSystem','OperatingSystemVersion',
              'LastLogonDate','Enabled','Description','DistinguishedName') |
              ForEach-Object { $obj.PSObject.Properties.Name | Should -Contain $_ }
        }
    }

    Context 'User type — SamAccountName exclusion (PII)' {

        BeforeAll {
            Mock Get-Module {
                [PSCustomObject]@{ Name = 'ActiveDirectory'; Version = '1.0.0.0' }
            } -ParameterFilter { $Name -eq 'ActiveDirectory' -and $ListAvailable }
            Mock Import-Module { }
            Mock Get-ADUser {
                @([PSCustomObject]@{
                    DisplayName       = 'Jane Smith'
                    EmailAddress      = 'jane@domain.local'
                    Department        = 'IT'
                    Title             = 'Engineer'
                    LastLogonDate     = (Get-Date).AddHours(-4)
                    Enabled           = $true
                    DistinguishedName = 'CN=Jane Smith,OU=Users,DC=domain,DC=local'
                    SamAccountName    = 'jsmith'   # this must NOT appear in results
                })
            }
        }

        It 'Returns user objects' {
            $result = Get-ComputerADInfo -Type 'User'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'User objects have expected properties' {
            $result = Get-ComputerADInfo -Type 'User'
            $obj    = $result | Select-Object -First 1
            @('DisplayName','EmailAddress','Department','Title',
              'LastLogonDate','Enabled','DistinguishedName') |
              ForEach-Object { $obj.PSObject.Properties.Name | Should -Contain $_ }
        }

        It 'SamAccountName is intentionally excluded from user results (PII)' {
            $result = Get-ComputerADInfo -Type 'User'
            $obj    = $result | Select-Object -First 1
            $obj.PSObject.Properties.Name | Should -Not -Contain 'SamAccountName'
        }
    }

    Context 'Group type' {

        BeforeAll {
            Mock Get-Module {
                [PSCustomObject]@{ Name = 'ActiveDirectory'; Version = '1.0.0.0' }
            } -ParameterFilter { $Name -eq 'ActiveDirectory' -and $ListAvailable }
            Mock Import-Module { }
            Mock Get-ADGroup {
                @([PSCustomObject]@{
                    Name           = 'Domain Admins'
                    SamAccountName = 'Domain Admins'
                    GroupCategory  = 'Security'
                    GroupScope     = 'Global'
                    Description    = 'Administrators of the domain'
                })
            }
        }

        It 'Returns group objects' {
            $result = Get-ComputerADInfo -Type 'Group'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Group objects have expected properties (including SamAccountName)' {
            $result = Get-ComputerADInfo -Type 'Group'
            $obj    = $result | Select-Object -First 1
            @('Name','SamAccountName','GroupCategory','GroupScope','Description') |
              ForEach-Object { $obj.PSObject.Properties.Name | Should -Contain $_ }
        }
    }

    Context 'Error path' {

        BeforeAll {
            Mock Get-Module {
                [PSCustomObject]@{ Name = 'ActiveDirectory'; Version = '1.0.0.0' }
            } -ParameterFilter { $Name -eq 'ActiveDirectory' -and $ListAvailable }
            Mock Import-Module { }
            Mock Get-ADComputer { throw 'AD query failure' }
        }

        It 'Returns $null on AD exception' {
            $result = Get-ComputerADInfo -Type 'Computer'
            $result | Should -BeNullOrEmpty
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Set-ComputerRDP' {

    Context 'Error path — CimSession cannot be opened' {

        BeforeAll {
            Mock New-CimSession { throw 'Simulated CIM failure' }
        }

        It 'Returns generic error string when CimSession cannot be opened' {
            $result = Set-ComputerRDP -ComputerName 'unreachable-host' -Enabled $true
            $result | Should -Match '^Error: RDP operation failed on '
        }

        It 'Error return does NOT expose exception detail' {
            $result = Set-ComputerRDP -ComputerName 'unreachable-host' -Enabled $true
            $result | Should -Not -Match 'Simulated'
            $result | Should -Not -Match 'CIM failure'
        }

        It 'Does NOT call Remove-CimSession when session was never assigned' {
            # $CimSession is $null before New-CimSession, which throws — finally block must not call Remove-CimSession
            Mock Remove-CimSession { }
            Set-ComputerRDP -ComputerName 'unreachable-host' -Enabled $true | Out-Null
            Should -Invoke Remove-CimSession -Times 0
        }
    }

    Context 'Success path — skipped when WinRM unavailable' -Skip:(-not $script:WinRMAvailable) {
        # New-CimSession is real (requires WinRM).  Get-CimInstance for both StdRegProv and
        # the firewall class is mocked so we don't depend on WMI provider availability.
        # Invoke-CimMethod and Set-CimInstance are mocked to control registry/firewall results.

        BeforeAll {
            $script:FakeCimRdpReg = [Microsoft.Management.Infrastructure.CimInstance]::new('StdRegProv')
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'StdRegProv' }          { $script:FakeCimRdpReg }
            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'MSFT_NetFirewallRule' } { @() }
            Mock Invoke-CimMethod { [PSCustomObject]@{ ReturnValue = 0 } }
            Mock Set-CimInstance  { }
        }

        It 'Returns "RDP Enabled on localhost" when Enabled=$true' {
            $result = Set-ComputerRDP -ComputerName 'localhost' -Enabled $true
            $result | Should -Be 'RDP Enabled on localhost'
        }

        It 'Returns "RDP Disabled on localhost" when Enabled=$false' {
            $result = Set-ComputerRDP -ComputerName 'localhost' -Enabled $false
            $result | Should -Be 'RDP Disabled on localhost'
        }

        It 'Calls Remove-CimSession in finally after success' {
            Mock Remove-CimSession { }
            Set-ComputerRDP -ComputerName 'localhost' -Enabled $false | Out-Null
            Should -Invoke Remove-CimSession -Times 1 -Exactly
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Test-ComputerPort' {

    Context 'Input validation' {

        It 'Throws on missing ComputerName (mandatory parameter)' {
            # ComputerName has [Parameter(Mandatory=$true)] — PowerShell will throw at binding
            { Test-ComputerPort -Port 80 } | Should -Throw
        }

        It 'Accepts default port 80 without error when New-Object throws' {
            # Even with a failing TcpClient, specifying no Port must not throw a binding error.
            Mock New-Object { throw 'Simulated socket failure' } -ParameterFilter {
                $TypeName -eq 'System.Net.Sockets.TcpClient'
            }
            $result = Test-ComputerPort -ComputerName 'localhost'
            $result | Should -Be 'Error'
        }
    }

    Context 'Error path — New-Object throws (e.g. DNS failure or socket error)' {

        BeforeAll {
            Mock New-Object { throw 'Simulated socket failure' } -ParameterFilter {
                $TypeName -eq 'System.Net.Sockets.TcpClient'
            }
        }

        It 'Returns "Error" when TcpClient creation throws' {
            $result = Test-ComputerPort -ComputerName 'unreachable.invalid' -Port 80
            $result | Should -Be 'Error'
        }

        It 'Return value is the string "Error" (not $null)' {
            $result = Test-ComputerPort -ComputerName 'unreachable.invalid' -Port 80
            $result | Should -BeOfType [string]
            $result | Should -Be 'Error'
        }
    }

    Context 'Return value is always one of three expected strings' {

        It 'Returns one of "Open", "Closed/Filtered", or "Error" for an unreachable host with a short timeout' {
            # Use a guaranteed-unreachable address and a minimal timeout to get a fast result.
            # We cannot control which of the three values is returned, but it must be one of them.
            $result = Test-ComputerPort -ComputerName '192.0.2.1' -Port 9 -TimeoutMs 100
            $result | Should -BeIn @('Open', 'Closed/Filtered', 'Error')
        }

        It 'Returns a non-null string' {
            $result = Test-ComputerPort -ComputerName '192.0.2.1' -Port 9 -TimeoutMs 100
            $result | Should -Not -BeNullOrEmpty
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Connect-ModernCloud (additional guards)' {
    # The basic happy-path and connection-exception tests are already covered in
    # the existing Connect-ModernCloud Describe block above.  This block adds the
    # guard tests specified in the feature matrix.

    Context 'Guard — Interactive and ClientId both specified' {

        It 'Returns "[!]" string when both -Interactive and -ClientId are provided' {
            $result = Connect-ModernCloud -Interactive -ClientId 'some-client-id'
            $result | Should -Match '^\[!\]'
        }

        It 'Returns the exact guard message' {
            $result = Connect-ModernCloud -Interactive -ClientId 'some-client-id'
            $result | Should -Be '[!] Specify either -Interactive or -ClientId/-ClientSecret, not both.'
        }

        It 'Does NOT call Connect-MgGraph when the guard fires' {
            Mock Connect-MgGraph { }
            Connect-ModernCloud -Interactive -ClientId 'some-client-id' | Out-Null
            Should -Invoke Connect-MgGraph -Times 0
        }
    }

    Context 'Guard — Service principal mode missing TenantId' {

        It 'Returns "[!]" string when TenantId is absent' {
            $secret = ConvertTo-SecureString 'dummy' -AsPlainText -Force
            $result = Connect-ModernCloud -ClientId 'cid' -ClientSecret $secret
            $result | Should -Match '^\[!\]'
        }

        It 'Returns the SP-mode guard message when TenantId is absent' {
            $secret = ConvertTo-SecureString 'dummy' -AsPlainText -Force
            $result = Connect-ModernCloud -ClientId 'cid' -ClientSecret $secret
            $result | Should -Be '[!] Service principal mode requires -TenantId, -ClientId, and -ClientSecret.'
        }
    }

    Context 'Guard — invalid TenantId format' {

        It 'Returns "[!]" string for a TenantId that is not a GUID or onmicrosoft.com domain' {
            $secret = ConvertTo-SecureString 'dummy' -AsPlainText -Force
            $result = Connect-ModernCloud -TenantId 'not-valid-format' -ClientId 'cid' -ClientSecret $secret
            $result | Should -Match '^\[!\]'
        }

        It 'Returns the TenantId format guard message' {
            $secret = ConvertTo-SecureString 'dummy' -AsPlainText -Force
            $result = Connect-ModernCloud -TenantId 'not-valid-format' -ClientId 'cid' -ClientSecret $secret
            $result | Should -Be '[!] TenantId must be a GUID or an onmicrosoft.com domain name.'
        }
    }

    Context 'Guard — valid GUID TenantId passes the format check' {

        It 'Does NOT return the TenantId format guard message for a valid GUID' {
            # The format guard fires only for non-GUID/non-onmicrosoft.com values.
            # A valid GUID must not trigger it — the function proceeds past the guard
            # (it may still fail to connect, but that is a different [!] message).
            $secret = ConvertTo-SecureString 'dummy' -AsPlainText -Force
            $result = Connect-ModernCloud -TenantId '12345678-1234-1234-1234-123456789012' -ClientId 'cid' -ClientSecret $secret
            $result | Should -Not -Be '[!] TenantId must be a GUID or an onmicrosoft.com domain name.'
        }
    }

    Context 'Guard — valid onmicrosoft.com TenantId passes the format check' {

        It 'Does NOT return the TenantId format guard message for a valid onmicrosoft.com domain' {
            $secret = ConvertTo-SecureString 'dummy' -AsPlainText -Force
            $result = Connect-ModernCloud -TenantId 'contoso.onmicrosoft.com' -ClientId 'cid' -ClientSecret $secret
            $result | Should -Not -Be '[!] TenantId must be a GUID or an onmicrosoft.com domain name.'
        }
    }

    Context 'Happy path Interactive — mock Connect-MgGraph and Get-MgContext' {

        BeforeAll {
            Mock Connect-MgGraph { }
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 'abc-123'; Account = 'user@test.com' } }
        }

        It 'Returns "[OK]" string' {
            $result = Connect-ModernCloud -Interactive
            $result | Should -Match '^\[OK\]'
        }

        It 'Calls Connect-MgGraph exactly once' {
            Connect-ModernCloud -Interactive | Out-Null
            Should -Invoke Connect-MgGraph -Times 1 -Exactly
        }

        It 'Calls Get-MgContext exactly once' {
            Connect-ModernCloud -Interactive | Out-Null
            Should -Invoke Get-MgContext -Times 1 -Exactly
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Connect-ExchangeSession' {

    BeforeAll {
        # Ensure Exchange cmdlets exist as stubs so Pester can mock them regardless of
        # whether ExchangeOnlineManagement is installed on the test runner.
        if (-not (Get-Command Connect-ExchangeOnline   -ErrorAction SilentlyContinue)) {
            function Connect-ExchangeOnline   { param([hashtable]$params) }
        }
        if (-not (Get-Command Get-OrganizationConfig   -ErrorAction SilentlyContinue)) {
            function Get-OrganizationConfig   { }
        }
    }

    Context 'Guard — ExchangeOnlineManagement module not found' {

        BeforeAll {
            Mock Get-Module { return $null } -ParameterFilter {
                $Name -eq 'ExchangeOnlineManagement' -and $ListAvailable
            }
        }

        It 'Returns "[!] ExchangeOnlineManagement module not found" string' {
            $result = Connect-ExchangeSession
            $result | Should -Match '^\[!\] ExchangeOnlineManagement module not found'
        }

        It 'Does NOT call Import-Module when the module guard fires' {
            Mock Import-Module { }
            Connect-ExchangeSession | Out-Null
            Should -Invoke Import-Module -Times 0
        }
    }

    Context 'Happy path — module present, connection succeeds' {

        BeforeAll {
            Mock Get-Module { [PSCustomObject]@{ Name = 'ExchangeOnlineManagement' } } -ParameterFilter {
                $Name -eq 'ExchangeOnlineManagement' -and $ListAvailable
            }
            Mock Import-Module { }
            Mock Connect-ExchangeOnline { }
            Mock Get-OrganizationConfig { [PSCustomObject]@{ DisplayName = 'Contoso' } }
        }

        It 'Returns "[OK]" string' {
            $result = Connect-ExchangeSession
            $result | Should -Match '^\[OK\]'
        }

        It 'Return value contains the organisation display name' {
            $result = Connect-ExchangeSession
            $result | Should -Match 'Contoso'
        }

        It 'Calls Connect-ExchangeOnline exactly once' {
            Connect-ExchangeSession | Out-Null
            Should -Invoke Connect-ExchangeOnline -Times 1 -Exactly
        }

        It 'Calls Get-OrganizationConfig exactly once' {
            Connect-ExchangeSession | Out-Null
            Should -Invoke Get-OrganizationConfig -Times 1 -Exactly
        }

        It 'Passes UserPrincipalName to Connect-ExchangeOnline when provided' {
            $script:CapturedConnectEXOParams = $null
            Mock Connect-ExchangeOnline {
                param([switch]$ShowBanner, [string]$UserPrincipalName, [string]$ErrorAction)
                $script:CapturedConnectEXOParams = $PSBoundParameters
            }
            Connect-ExchangeSession -UserPrincipalName 'admin@contoso.com' | Out-Null
            $script:CapturedConnectEXOParams.ContainsKey('UserPrincipalName') | Should -BeTrue
        }
    }

    Context 'Error path — Connect-ExchangeOnline throws' {

        BeforeAll {
            Mock Get-Module { [PSCustomObject]@{ Name = 'ExchangeOnlineManagement' } } -ParameterFilter {
                $Name -eq 'ExchangeOnlineManagement' -and $ListAvailable
            }
            Mock Import-Module { }
            Mock Connect-ExchangeOnline { throw 'Authentication failed' }
        }

        It 'Returns "[!]" string on connection failure' {
            $result = Connect-ExchangeSession
            $result | Should -Match '^\[!\]'
        }

        It 'Does NOT surface exception text in the return value' {
            $result = Connect-ExchangeSession
            $result | Should -Not -Match 'Authentication failed'
            $result | Should -Not -Match 'Exception'
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Get-DeviceComplianceStatus' {

    Context 'Result list shape' {

        BeforeAll {
            Mock Get-ItemProperty { $null }
            Mock Test-Path { $false }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Pro' } }
        }

        It 'Returns exactly 5 items' {
            $result = Get-DeviceComplianceStatus
            @($result).Count | Should -Be 5
        }

        It 'Every item has Item, Status, and Description properties' {
            $result = Get-DeviceComplianceStatus
            foreach ($item in $result) {
                $item.PSObject.Properties.Name | Should -Contain 'Item'
                $item.PSObject.Properties.Name | Should -Contain 'Status'
                $item.PSObject.Properties.Name | Should -Contain 'Description'
            }
        }

        It 'Item names are the expected five labels' {
            $result  = Get-DeviceComplianceStatus
            $names   = $result | ForEach-Object { $_.Item }
            $names   | Should -Contain 'Location Services'
            $names   | Should -Contain 'OneDrive'
            $names   | Should -Contain 'Outlook External Images'
            $names   | Should -Contain 'Windows Update Active Hours'
            $names   | Should -Contain 'Unified Write Filter'
        }
    }

    Context 'Location Services — Compliant when policy not blocked, service cfg=1, consent=Allow' {

        BeforeAll {
            Mock Get-ItemProperty {
                param($Path)
                switch -Wildcard ($Path) {
                    '*LocationAndSensors*' {
                        [PSCustomObject]@{ DisableLocation = 0; DisableWindowsLocationProvider = 0; DisableSensors = 0 }
                    }
                    '*lfsvc*' {
                        [PSCustomObject]@{ Status = 1 }
                    }
                    '*ConsentStore\location*' {
                        [PSCustomObject]@{ Value = 'Allow' }
                    }
                    default { $null }
                }
            }
            Mock Test-Path { $false }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Pro' } }
        }

        It 'Location Services Status is Compliant' {
            $result = Get-DeviceComplianceStatus
            $item   = $result | Where-Object { $_.Item -eq 'Location Services' }
            $item.Status | Should -Be 'Compliant'
        }
    }

    Context 'Location Services — Non-Compliant when DisableLocation = 1' {

        BeforeAll {
            Mock Get-ItemProperty {
                param($Path)
                switch -Wildcard ($Path) {
                    '*LocationAndSensors*' {
                        [PSCustomObject]@{ DisableLocation = 1; DisableWindowsLocationProvider = 0; DisableSensors = 0 }
                    }
                    default { $null }
                }
            }
            Mock Test-Path { $false }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Pro' } }
        }

        It 'Location Services Status is Non-Compliant when policy is locked' {
            $result = Get-DeviceComplianceStatus
            $item   = $result | Where-Object { $_.Item -eq 'Location Services' }
            $item.Status | Should -Be 'Non-Compliant'
        }
    }

    Context 'OneDrive — Installed when setup exe found' {

        BeforeAll {
            Mock Get-ItemProperty { $null }
            Mock Test-Path {
                param($Path)
                # Return $true for the System32 OneDriveSetup path
                $Path -like '*System32*OneDriveSetup.exe*'
            }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Pro' } }
        }

        It 'OneDrive Status is Installed when System32 setup exe exists' {
            $result = Get-DeviceComplianceStatus
            $item   = $result | Where-Object { $_.Item -eq 'OneDrive' }
            $item.Status | Should -Be 'Installed'
        }
    }

    Context 'OneDrive — Not Installed when no setup exe found' {

        BeforeAll {
            Mock Get-ItemProperty { $null }
            Mock Test-Path { $false }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Pro' } }
        }

        It 'OneDrive Status is Not Installed when no exe found' {
            $result = Get-DeviceComplianceStatus
            $item   = $result | Where-Object { $_.Item -eq 'OneDrive' }
            $item.Status | Should -Be 'Not Installed'
        }
    }

    Context 'Outlook External Images — various BlockExtContent values' {

        It 'Status is Compliant when BlockExtContent = 0' {
            Mock Get-ItemProperty {
                param($Path)
                if ($Path -like '*Outlook*Mail*') { [PSCustomObject]@{ BlockExtContent = 0 } }
                else { $null }
            }
            Mock Test-Path { $false }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Pro' } }

            $result = Get-DeviceComplianceStatus
            $item   = $result | Where-Object { $_.Item -eq 'Outlook External Images' }
            $item.Status | Should -Be 'Compliant'
        }

        It 'Status is Blocked when BlockExtContent = 1' {
            Mock Get-ItemProperty {
                param($Path)
                if ($Path -like '*Outlook*Mail*') { [PSCustomObject]@{ BlockExtContent = 1 } }
                else { $null }
            }
            Mock Test-Path { $false }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Pro' } }

            $result = Get-DeviceComplianceStatus
            $item   = $result | Where-Object { $_.Item -eq 'Outlook External Images' }
            $item.Status | Should -Be 'Blocked'
        }

        It 'Status is Not Configured when BlockExtContent key is absent' {
            Mock Get-ItemProperty { $null }
            Mock Test-Path { $false }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Pro' } }

            $result = Get-DeviceComplianceStatus
            $item   = $result | Where-Object { $_.Item -eq 'Outlook External Images' }
            $item.Status | Should -Be 'Not Configured'
        }
    }

    Context 'Windows Update Active Hours' {

        It 'Status is Configured when both ActiveHoursStart and ActiveHoursEnd are present' {
            Mock Get-ItemProperty {
                param($Path)
                if ($Path -like '*WindowsUpdate*') { [PSCustomObject]@{ ActiveHoursStart = 8; ActiveHoursEnd = 18 } }
                else { $null }
            }
            Mock Test-Path { $false }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Pro' } }

            $result = Get-DeviceComplianceStatus
            $item   = $result | Where-Object { $_.Item -eq 'Windows Update Active Hours' }
            $item.Status | Should -Be 'Configured'
        }

        It 'Status is Not Configured when active hours keys are absent' {
            Mock Get-ItemProperty { $null }
            Mock Test-Path { $false }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Pro' } }

            $result = Get-DeviceComplianceStatus
            $item   = $result | Where-Object { $_.Item -eq 'Windows Update Active Hours' }
            $item.Status | Should -Be 'Not Configured'
        }
    }

    Context 'Unified Write Filter — N/A on non-Enterprise OS' {

        BeforeAll {
            Mock Get-ItemProperty { $null }
            Mock Test-Path { $false }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Pro' } }
        }

        It 'UWF Status is N/A on non-Enterprise Windows' {
            $result = Get-DeviceComplianceStatus
            $item   = $result | Where-Object { $_.Item -eq 'Unified Write Filter' }
            $item.Status | Should -Be 'N/A'
        }
    }

    Context 'Error resilience — if one item throws, others still return results' {

        BeforeAll {
            # Make Get-ItemProperty throw to induce errors in the registry-reading items,
            # but Get-CimInstance must still succeed for UWF item.
            Mock Get-ItemProperty { throw 'Simulated registry failure' }
            Mock Test-Path { throw 'Simulated filesystem failure' }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Windows 10 Pro' } }
        }

        It 'Still returns exactly 5 items even when individual checks throw' {
            $result = Get-DeviceComplianceStatus
            @($result).Count | Should -Be 5
        }

        It 'Failed items report Status "Error"' {
            $result      = Get-DeviceComplianceStatus
            $errorItems  = $result | Where-Object { $_.Status -eq 'Error' }
            @($errorItems).Count | Should -BeGreaterThan 0
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Set-DeviceComplianceItem' {

    Context 'LocationServices — happy path' {

        BeforeAll {
            Mock Set-ItemProperty { }
            Mock New-Item { [PSCustomObject]@{ PSPath = 'HKLM:\...' } }
            Mock Test-Path { $true }   # paths already exist → New-Item not called
            Mock Restart-Service { }
            # Mock the HKEY_USERS enumeration used in the foreach loop
            Mock Get-ChildItem { @() } -ParameterFilter { $Path -like 'Registry::HKEY_USERS' }
        }

        It 'Returns "[OK]" string for LocationServices' {
            $result = Set-DeviceComplianceItem -Item 'LocationServices'
            $result | Should -Match '^\[OK\]'
        }

        It 'Calls Set-ItemProperty at least once for LocationServices' {
            Set-DeviceComplianceItem -Item 'LocationServices' | Out-Null
            Should -Invoke Set-ItemProperty -Times 1
        }

        It 'Calls Restart-Service for lfsvc' {
            Set-DeviceComplianceItem -Item 'LocationServices' | Out-Null
            Should -Invoke Restart-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'lfsvc' }
        }
    }

    Context 'OutlookExternalImages — happy path' {

        BeforeAll {
            Mock Set-ItemProperty { }
            Mock New-Item { [PSCustomObject]@{ PSPath = 'HKCU:\...' } }
            Mock Test-Path { $true }
        }

        It 'Returns "[OK]" string for OutlookExternalImages' {
            $result = Set-DeviceComplianceItem -Item 'OutlookExternalImages'
            $result | Should -Match '^\[OK\]'
        }

        It 'Calls Set-ItemProperty with BlockExtContent = 0' {
            $script:CapturedOEIValue = $null
            Mock Set-ItemProperty {
                param($Path, $Name, $Value)
                if ($Name -eq 'BlockExtContent') { $script:CapturedOEIValue = $Value }
            }
            Set-DeviceComplianceItem -Item 'OutlookExternalImages' | Out-Null
            $script:CapturedOEIValue | Should -Be 0
        }
    }

    Context 'WindowsUpdateActiveHours — happy path' {

        BeforeAll {
            Mock Set-ItemProperty { }
            Mock New-Item { [PSCustomObject]@{ PSPath = 'HKLM:\...' } }
            Mock Test-Path { $true }
        }

        It 'Returns "[OK]" string for WindowsUpdateActiveHours' {
            $result = Set-DeviceComplianceItem -Item 'WindowsUpdateActiveHours' -ActiveHoursStart 8 -ActiveHoursEnd 18
            $result | Should -Match '^\[OK\]'
        }

        It 'Return value includes the configured hours' {
            $result = Set-DeviceComplianceItem -Item 'WindowsUpdateActiveHours' -ActiveHoursStart 9 -ActiveHoursEnd 17
            $result | Should -Match '9:00'
            $result | Should -Match '17:00'
        }

        It 'Calls Set-ItemProperty for ActiveHoursStart and ActiveHoursEnd' {
            Set-DeviceComplianceItem -Item 'WindowsUpdateActiveHours' -ActiveHoursStart 8 -ActiveHoursEnd 18 | Out-Null
            Should -Invoke Set-ItemProperty -Times 1 -ParameterFilter { $Name -eq 'ActiveHoursStart' }
            Should -Invoke Set-ItemProperty -Times 1 -ParameterFilter { $Name -eq 'ActiveHoursEnd' }
        }
    }

    Context 'WindowsUpdateActiveHours — guard: start equals end' {

        BeforeAll {
            Mock Set-ItemProperty { }
            Mock Test-Path { $true }
        }

        It 'Returns "[!]" string when ActiveHoursStart equals ActiveHoursEnd' {
            $result = Set-DeviceComplianceItem -Item 'WindowsUpdateActiveHours' -ActiveHoursStart 12 -ActiveHoursEnd 12
            $result | Should -Match '^\[!\]'
        }

        It 'Does NOT call Set-ItemProperty when start equals end' {
            Set-DeviceComplianceItem -Item 'WindowsUpdateActiveHours' -ActiveHoursStart 12 -ActiveHoursEnd 12 | Out-Null
            Should -Invoke Set-ItemProperty -Times 0
        }
    }

    Context 'RemoveOneDrive — no installer found (cleanup-only path)' {

        BeforeAll {
            Mock Get-Process { }
            Mock Stop-Process { }
            Mock Test-Path { $false }   # setup exe not found → uninstallRan stays $false
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } }
            Mock Remove-Item { }
            Mock Remove-ItemProperty { }
        }

        It 'Returns "[!] OneDrive uninstaller not found..." string when no setup exe is present' {
            # When Test-Path returns $false for both setup exe paths, $uninstallRan stays $false
            # and the function returns the not-found cleanup message (prefixed with [!]).
            $result = Set-DeviceComplianceItem -Item 'RemoveOneDrive'
            $result | Should -Match '^\[!\] OneDrive uninstaller not found'
        }

        It 'Calls Get-Process to find the OneDrive process' {
            Set-DeviceComplianceItem -Item 'RemoveOneDrive' | Out-Null
            Should -Invoke Get-Process -Times 1 -ParameterFilter { $Name -eq 'OneDrive' }
        }
    }

    Context 'RemoveOneDrive — installer found and runs successfully' {

        BeforeAll {
            Mock Get-Process { }
            Mock Stop-Process { }
            # Return $true only for the System32 path so Start-Process is called exactly once.
            Mock Test-Path {
                param($Path)
                $Path -like '*System32*OneDriveSetup.exe*'
            }
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } }
            Mock Remove-Item { }
            Mock Remove-ItemProperty { }
        }

        It 'Returns "[OK]" string when uninstaller runs and exits cleanly' {
            $result = Set-DeviceComplianceItem -Item 'RemoveOneDrive'
            $result | Should -Match '^\[OK\]'
        }

        It 'Calls Start-Process exactly once to run the uninstaller' {
            Set-DeviceComplianceItem -Item 'RemoveOneDrive' | Out-Null
            Should -Invoke Start-Process -Times 1 -Exactly
        }
    }

    Context 'Input validation' {

        It 'Throws on an invalid Item value (ValidateSet enforcement)' {
            { Set-DeviceComplianceItem -Item 'InvalidItem' } | Should -Throw
        }

        It 'Throws when ActiveHoursStart is out of range (24)' {
            { Set-DeviceComplianceItem -Item 'WindowsUpdateActiveHours' -ActiveHoursStart 24 } | Should -Throw
        }

        It 'Throws when ActiveHoursEnd is out of range (24)' {
            { Set-DeviceComplianceItem -Item 'WindowsUpdateActiveHours' -ActiveHoursEnd 24 } | Should -Throw
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Get-ExchangeMailboxPermission' {

    BeforeAll {
        # Stub Exchange cmdlets so Pester can mock them on systems without the module.
        if (-not (Get-Command Get-Mailbox            -ErrorAction SilentlyContinue)) {
            function Get-Mailbox            { param([string]$RecipientTypeDetails, [string]$ErrorAction) }
        }
        if (-not (Get-Command Get-MailboxPermission  -ErrorAction SilentlyContinue)) {
            function Get-MailboxPermission  { param([string]$Identity, [string]$ErrorAction) }
        }
        if (-not (Get-Command Get-RecipientPermission -ErrorAction SilentlyContinue)) {
            function Get-RecipientPermission { param([string]$Identity, [string]$ErrorAction) }
        }
    }

    Context 'Happy path — user holds FullAccess on first mailbox and SendAs on second' {

        BeforeAll {
            Mock Get-Mailbox {
                @(
                    [PSCustomObject]@{ Alias = 'mb1'; PrimarySmtpAddress = 'mb1@contoso.com'; DisplayName = 'Mailbox 1' },
                    [PSCustomObject]@{ Alias = 'mb2'; PrimarySmtpAddress = 'mb2@contoso.com'; DisplayName = 'Mailbox 2' }
                )
            }
            Mock Get-MailboxPermission {
                param([string]$Identity)
                if ($Identity -eq 'mb1') {
                    [PSCustomObject]@{ User = 'user@contoso.com'; AccessRights = @('FullAccess') }
                }
            }
            Mock Get-RecipientPermission {
                param([string]$Identity)
                if ($Identity -eq 'mb2') {
                    [PSCustomObject]@{ Trustee = 'user@contoso.com'; AccessRights = @('SendAs') }
                }
            }
        }

        It 'Returns 2 objects' {
            $result = Get-ExchangeMailboxPermission -UserPrincipalName 'user@contoso.com'
            @($result).Count | Should -Be 2
        }

        It 'Result objects have Mailbox, DisplayName, FullAccess, SendAs properties' {
            $result = Get-ExchangeMailboxPermission -UserPrincipalName 'user@contoso.com'
            $obj    = $result | Select-Object -First 1
            $obj.PSObject.Properties.Name | Should -Contain 'Mailbox'
            $obj.PSObject.Properties.Name | Should -Contain 'DisplayName'
            $obj.PSObject.Properties.Name | Should -Contain 'FullAccess'
            $obj.PSObject.Properties.Name | Should -Contain 'SendAs'
        }

        It 'First result has FullAccess = $true for mb1' {
            $result = Get-ExchangeMailboxPermission -UserPrincipalName 'user@contoso.com'
            $mb1    = $result | Where-Object { $_.Mailbox -eq 'mb1@contoso.com' }
            $mb1.FullAccess | Should -BeTrue
        }

        It 'Second result has SendAs = $true for mb2' {
            $result = Get-ExchangeMailboxPermission -UserPrincipalName 'user@contoso.com'
            $mb2    = $result | Where-Object { $_.Mailbox -eq 'mb2@contoso.com' }
            $mb2.SendAs | Should -BeTrue
        }
    }

    Context 'User has no permissions on any mailbox' {

        BeforeAll {
            Mock Get-Mailbox {
                @(
                    [PSCustomObject]@{ Alias = 'mb1'; PrimarySmtpAddress = 'mb1@contoso.com'; DisplayName = 'Mailbox 1' }
                )
            }
            Mock Get-MailboxPermission  { }   # returns nothing
            Mock Get-RecipientPermission { }  # returns nothing
        }

        It 'Returns empty (no objects) when user has no permissions' {
            $result = Get-ExchangeMailboxPermission -UserPrincipalName 'noone@contoso.com'
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Error path — Get-Mailbox throws' {

        BeforeAll {
            Mock Get-Mailbox { throw 'Not connected to Exchange Online' }
        }

        It 'Returns $null when Get-Mailbox throws' {
            $result = Get-ExchangeMailboxPermission -UserPrincipalName 'user@contoso.com'
            $result | Should -BeNullOrEmpty
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Set-ExchangeMailboxPermission' {

    BeforeAll {
        # Stub Exchange cmdlets so Pester can mock them on systems without the module.
        if (-not (Get-Command Get-Mailbox              -ErrorAction SilentlyContinue)) {
            function Get-Mailbox              { param([string]$RecipientTypeDetails, [string]$ErrorAction) }
        }
        if (-not (Get-Command Get-MailboxPermission    -ErrorAction SilentlyContinue)) {
            function Get-MailboxPermission    { param([string]$Identity, [string]$ErrorAction) }
        }
        if (-not (Get-Command Get-RecipientPermission  -ErrorAction SilentlyContinue)) {
            function Get-RecipientPermission  { param([string]$Identity, [string]$ErrorAction) }
        }
        if (-not (Get-Command Add-MailboxPermission    -ErrorAction SilentlyContinue)) {
            function Add-MailboxPermission    { param([string]$Identity, [string]$User, [string[]]$AccessRights, [string]$InheritanceType, [switch]$AutoMapping, [string]$ErrorAction) }
        }
        if (-not (Get-Command Add-RecipientPermission  -ErrorAction SilentlyContinue)) {
            function Add-RecipientPermission  { param([string]$Identity, [string]$Trustee, [string[]]$AccessRights, [switch]$Confirm, [string]$ErrorAction) }
        }
    }

    Context 'Guard — Mirror missing SourceUser' {

        It 'Returns "[!]" string when SourceUser is absent in Mirror mode' {
            $result = Set-ExchangeMailboxPermission -Action 'Mirror' -TargetUser 'target@contoso.com'
            $result | Should -Match '^\[!\]'
        }

        It 'Returns the Mirror-specific guard message when SourceUser is absent' {
            $result = Set-ExchangeMailboxPermission -Action 'Mirror' -TargetUser 'target@contoso.com'
            $result | Should -Be '[!] Mirror requires both SourceUser and TargetUser.'
        }
    }

    Context 'Guard — Mirror missing TargetUser' {

        It 'Returns "[!]" string when TargetUser is absent in Mirror mode' {
            $result = Set-ExchangeMailboxPermission -Action 'Mirror' -SourceUser 'source@contoso.com'
            $result | Should -Match '^\[!\]'
        }

        It 'Returns the Mirror-specific guard message when TargetUser is absent' {
            $result = Set-ExchangeMailboxPermission -Action 'Mirror' -SourceUser 'source@contoso.com'
            $result | Should -Be '[!] Mirror requires both SourceUser and TargetUser.'
        }
    }

    Context 'Guard — Grant missing Mailbox' {

        It 'Returns "[!]" string when Mailbox is absent in Grant mode' {
            $result = Set-ExchangeMailboxPermission -Action 'Grant' -User 'user@contoso.com'
            $result | Should -Match '^\[!\]'
        }

        It 'Returns the Grant-specific guard message when Mailbox is absent' {
            $result = Set-ExchangeMailboxPermission -Action 'Grant' -User 'user@contoso.com'
            $result | Should -Be '[!] Grant requires both Mailbox and User.'
        }
    }

    Context 'Guard — Grant missing User' {

        It 'Returns "[!]" string when User is absent in Grant mode' {
            $result = Set-ExchangeMailboxPermission -Action 'Grant' -Mailbox 'shared@contoso.com'
            $result | Should -Match '^\[!\]'
        }

        It 'Returns the Grant-specific guard message when User is absent' {
            $result = Set-ExchangeMailboxPermission -Action 'Grant' -Mailbox 'shared@contoso.com'
            $result | Should -Be '[!] Grant requires both Mailbox and User.'
        }
    }

    Context 'Mirror happy path — source user has FullAccess on one mailbox' {

        BeforeAll {
            Mock Get-Mailbox {
                @(
                    [PSCustomObject]@{ Alias = 'mb1'; PrimarySmtpAddress = 'mb1@contoso.com'; DisplayName = 'Mailbox 1' }
                )
            }
            Mock Get-MailboxPermission {
                [PSCustomObject]@{ User = 'source@contoso.com'; AccessRights = @('FullAccess') }
            }
            Mock Get-RecipientPermission { }  # no SendAs
            Mock Add-MailboxPermission   { }
            Mock Add-RecipientPermission { }
        }

        It 'Returns "[OK]" string' {
            $result = Set-ExchangeMailboxPermission -Action 'Mirror' `
                        -SourceUser 'source@contoso.com' -TargetUser 'target@contoso.com'
            $result | Should -Match '^\[OK\]'
        }

        It 'Return value includes the permission count and both users' {
            $result = Set-ExchangeMailboxPermission -Action 'Mirror' `
                        -SourceUser 'source@contoso.com' -TargetUser 'target@contoso.com'
            $result | Should -Match 'source@contoso.com'
            $result | Should -Match 'target@contoso.com'
        }

        It 'Calls Add-MailboxPermission for the FullAccess grant' {
            Set-ExchangeMailboxPermission -Action 'Mirror' `
                -SourceUser 'source@contoso.com' -TargetUser 'target@contoso.com' | Out-Null
            Should -Invoke Add-MailboxPermission -Times 1 -Exactly
        }
    }

    Context 'Mirror — no permissions on source user' {

        BeforeAll {
            Mock Get-Mailbox {
                @(
                    [PSCustomObject]@{ Alias = 'mb1'; PrimarySmtpAddress = 'mb1@contoso.com'; DisplayName = 'Mailbox 1' }
                )
            }
            Mock Get-MailboxPermission   { }  # no FA
            Mock Get-RecipientPermission { }  # no SA
        }

        It 'Returns "[!] No shared mailbox permissions found..." string' {
            $result = Set-ExchangeMailboxPermission -Action 'Mirror' `
                        -SourceUser 'nobody@contoso.com' -TargetUser 'target@contoso.com'
            $result | Should -Match '^\[!\] No shared mailbox permissions found'
        }
    }

    Context 'Grant happy path' {

        BeforeAll {
            Mock Add-MailboxPermission   { }
            Mock Add-RecipientPermission { }
        }

        It 'Returns "[OK] Granted FullAccess and SendAs..." string' {
            $result = Set-ExchangeMailboxPermission -Action 'Grant' `
                        -Mailbox 'shared@contoso.com' -User 'user@contoso.com'
            $result | Should -Match '^\[OK\] Granted FullAccess and SendAs'
        }

        It 'Return value includes the mailbox and user' {
            $result = Set-ExchangeMailboxPermission -Action 'Grant' `
                        -Mailbox 'shared@contoso.com' -User 'user@contoso.com'
            $result | Should -Match 'shared@contoso.com'
            $result | Should -Match 'user@contoso.com'
        }

        It 'Calls Add-MailboxPermission exactly once' {
            Set-ExchangeMailboxPermission -Action 'Grant' `
                -Mailbox 'shared@contoso.com' -User 'user@contoso.com' | Out-Null
            Should -Invoke Add-MailboxPermission -Times 1 -Exactly
        }

        It 'Calls Add-RecipientPermission exactly once' {
            Set-ExchangeMailboxPermission -Action 'Grant' `
                -Mailbox 'shared@contoso.com' -User 'user@contoso.com' | Out-Null
            Should -Invoke Add-RecipientPermission -Times 1 -Exactly
        }
    }

    Context 'Error path — Add-MailboxPermission throws' {

        BeforeAll {
            Mock Add-MailboxPermission { throw 'Simulated Exchange failure' }
        }

        It 'Returns "[!]" string when Add-MailboxPermission throws' {
            $result = Set-ExchangeMailboxPermission -Action 'Grant' `
                        -Mailbox 'shared@contoso.com' -User 'user@contoso.com'
            $result | Should -Match '^\[!\]'
        }

        It 'Does NOT surface exception text in the return value' {
            $result = Set-ExchangeMailboxPermission -Action 'Grant' `
                        -Mailbox 'shared@contoso.com' -User 'user@contoso.com'
            $result | Should -Not -Match 'Simulated Exchange failure'
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Get-IntuneManagementScript' {

    BeforeAll {
        # Ensure Invoke-MgGraphRequest stub exists so Pester can mock it on runners
        # where Microsoft.Graph.Authentication is not installed.
        if (-not (Get-Command Invoke-MgGraphRequest -ErrorAction SilentlyContinue)) {
            function Invoke-MgGraphRequest { param([string]$Method, [string]$Uri, [string]$ErrorAction) }
        }
        if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue)) {
            function Get-MgContext { }
        }
    }

    Context 'Guard — not connected to Graph' {

        BeforeAll {
            Mock Get-MgContext { return $null }
        }

        It 'Returns $null when not connected to Graph' {
            $result = Get-IntuneManagementScript
            $result | Should -BeNullOrEmpty
        }

        It 'Does NOT call Invoke-MgGraphRequest when the guard fires' {
            Mock Invoke-MgGraphRequest { }
            Get-IntuneManagementScript | Out-Null
            Should -Invoke Invoke-MgGraphRequest -Times 0
        }
    }

    Context 'Happy path — two scripts returned' {

        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 'abc' } }
            Mock Invoke-MgGraphRequest {
                @{
                    value = @(
                        @{ id = '1'; displayName = 'Script One'; fileName = 'one.ps1'
                           runAsAccount = 'System'; enforcementType = 'required'
                           createdDateTime = '2024-01-01'; lastModifiedDateTime = '2024-01-02'
                           scriptContent = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('# script one')) },
                        @{ id = '2'; displayName = 'Script Two'; fileName = 'two.ps1'
                           runAsAccount = 'User'; enforcementType = 'available'
                           createdDateTime = '2024-02-01'; lastModifiedDateTime = '2024-02-02'
                           scriptContent = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('# script two')) }
                    )
                }
            }
            Mock Out-File { }
            Mock New-Item { }
            Mock Test-Path { $true }
        }

        It 'Returns 2 objects' {
            $result = Get-IntuneManagementScript
            @($result).Count | Should -Be 2
        }

        It 'Result objects have Id, DisplayName, FileName, RunAs, Enforcement, Created, Modified properties' {
            $result = Get-IntuneManagementScript
            $obj    = $result | Select-Object -First 1
            foreach ($prop in @('Id','DisplayName','FileName','RunAs','Enforcement','Created','Modified')) {
                $obj.PSObject.Properties.Name | Should -Contain $prop
            }
        }

        It 'Id and DisplayName values are correctly mapped' {
            $result = Get-IntuneManagementScript
            ($result | Where-Object { $_.Id -eq '1' }).DisplayName | Should -Be 'Script One'
            ($result | Where-Object { $_.Id -eq '2' }).DisplayName | Should -Be 'Script Two'
        }

        It 'Calls Invoke-MgGraphRequest exactly once (list call only)' {
            Get-IntuneManagementScript | Out-Null
            Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly
        }
    }

    Context 'Search filter — returns only matching scripts' {

        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 'abc' } }
            Mock Invoke-MgGraphRequest {
                @{
                    value = @(
                        @{ id = '1'; displayName = 'Deploy Chrome'; fileName = 'deploy-chrome.ps1'
                           runAsAccount = 'System'; enforcementType = 'required'
                           createdDateTime = '2024-01-01'; lastModifiedDateTime = '2024-01-02'; scriptContent = '' },
                        @{ id = '2'; displayName = 'Cleanup Temp'; fileName = 'cleanup-temp.ps1'
                           runAsAccount = 'System'; enforcementType = 'required'
                           createdDateTime = '2024-01-01'; lastModifiedDateTime = '2024-01-02'; scriptContent = '' },
                        @{ id = '3'; displayName = 'Deploy Firefox'; fileName = 'deploy-firefox.ps1'
                           runAsAccount = 'System'; enforcementType = 'required'
                           createdDateTime = '2024-01-01'; lastModifiedDateTime = '2024-01-02'; scriptContent = '' }
                    )
                }
            }
            Mock Out-File { }
            Mock Test-Path { $true }
        }

        It 'Returns only scripts matching the Search filter' {
            $result = Get-IntuneManagementScript -Search 'Deploy'
            @($result).Count | Should -Be 2
        }

        It 'All returned scripts match the search term in DisplayName or FileName' {
            $result = Get-IntuneManagementScript -Search 'Deploy'
            $result | ForEach-Object {
                ($_.DisplayName -like '*Deploy*' -or $_.FileName -like '*deploy*') | Should -BeTrue
            }
        }
    }

    Context 'Download path — detail endpoint called for each script' {
        # Note: Out-File cannot be reliably mocked in Pester because the proxy's parameter
        # validation rejects -Encoding UTF8 (string) before the mock body executes.
        # We instead verify that Invoke-MgGraphRequest is called once per script for the
        # detail endpoint (1 list call + N detail calls = N+1 total).

        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 'abc' } }

            # Any call returns the list plus valid detail payload.
            Mock Invoke-MgGraphRequest {
                @{
                    value = @(
                        @{ id = '1'; displayName = 'Script One'; fileName = 'one.ps1'
                           runAsAccount = 'System'; enforcementType = 'required'
                           createdDateTime = '2024-01-01'; lastModifiedDateTime = '2024-01-02'
                           scriptContent = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('# content')) },
                        @{ id = '2'; displayName = 'Script Two'; fileName = 'two.ps1'
                           runAsAccount = 'User'; enforcementType = 'available'
                           createdDateTime = '2024-02-01'; lastModifiedDateTime = '2024-02-02'
                           scriptContent = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('# content')) }
                    )
                    fileName      = 'script.ps1'
                    scriptContent = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('# content'))
                }
            }
            Mock New-Item { }
            Mock Test-Path { $true }
        }

        It 'Calls Invoke-MgGraphRequest N+1 times when DownloadPath is provided (list + N detail calls)' {
            # 2 scripts → 1 list + 2 detail calls = 3 total
            Get-IntuneManagementScript -DownloadPath 'C:\Temp\Scripts' | Out-Null
            Should -Invoke Invoke-MgGraphRequest -Times 3 -Exactly
        }

        It 'Calls Invoke-MgGraphRequest only once (list only) when no DownloadPath is specified' {
            Get-IntuneManagementScript | Out-Null
            Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly
        }
    }

    Context 'Error path — Invoke-MgGraphRequest throws' {

        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 'abc' } }
            Mock Invoke-MgGraphRequest { throw 'Graph API error' }
        }

        It 'Returns $null when Invoke-MgGraphRequest throws' {
            $result = Get-IntuneManagementScript
            $result | Should -BeNullOrEmpty
        }
    }
}
