#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost', '',
    Justification = 'Test file uses Write-Host in mock assertions.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingComputerNameHardcoded', '',
    Justification = 'Test fixtures require hardcoded computer names as test inputs.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Mock stub functions declare params to match real signatures.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingConvertToSecureStringWithPlainText', '',
    Justification = 'Test verifies credentials are NOT exposed — requires known plaintext.')]
param()

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

    # ── Graph / Az cmdlet stubs ──────────────────────────────────────────────
    # Pester v5 cannot Mock a command that doesn't exist. On a dev box without
    # the Microsoft.Graph.* / Az.* modules installed, these cmdlets are absent
    # and every Mock of them throws CommandNotFoundException (17 failures on a
    # clean machine). Define no-op stubs — matching the parameters the private
    # functions actually pass — ONLY when the real command is missing, so Mock
    # has something to attach to. When the real modules are present (e.g. CI),
    # each guard is false and the real cmdlets are used: identical behaviour to
    # before. Mirrors the Exchange stub pattern in the Set-/Get-Exchange* tests.
    if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue)) {
        function Get-MgContext { }
    }
    if (-not (Get-Command Connect-MgGraph -ErrorAction SilentlyContinue)) {
        function Connect-MgGraph { param([string[]]$Scopes, [string]$TenantId, [string]$ClientId, [pscredential]$ClientSecretCredential) }
    }
    if (-not (Get-Command Get-MgUser -ErrorAction SilentlyContinue)) {
        function Get-MgUser { param([string]$Filter, [int]$Top) }
    }
    if (-not (Get-Command Get-MgGroup -ErrorAction SilentlyContinue)) {
        function Get-MgGroup { param([string]$Filter, [int]$Top) }
    }
    if (-not (Get-Command Get-MgDeviceManagementManagedDevice -ErrorAction SilentlyContinue)) {
        function Get-MgDeviceManagementManagedDevice { param([string]$Filter, [int]$Top) }
    }
    if (-not (Get-Command Get-AzContext -ErrorAction SilentlyContinue)) {
        function Get-AzContext { }
    }
    if (-not (Get-Command Search-AzGraph -ErrorAction SilentlyContinue)) {
        function Search-AzGraph { param([string]$Query) }
    }
    # Get-AzResource is never called by the code under test — it is mocked only so
    # tests can assert it is NOT invoked (Search-AzGraph is used instead). The
    # negative assertion still needs the command to resolve on a clean box.
    if (-not (Get-Command Get-AzResource -ErrorAction SilentlyContinue)) {
        function Get-AzResource { param([string]$ResourceType, [string]$Name) }
    }
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
Describe 'Invoke-ComputerServiceControl' {

    Context 'Parameter validation' {
        It 'Requires -ComputerName' {
            { Invoke-ComputerServiceControl -ServiceName 'spooler' -Action 'Stop' } |
                Should -Throw
        }
        It 'Requires -ServiceName' {
            { Invoke-ComputerServiceControl -ComputerName 'localhost' -Action 'Stop' } |
                Should -Throw
        }
        It 'Requires -Action' {
            { Invoke-ComputerServiceControl -ComputerName 'localhost' -ServiceName 'spooler' } |
                Should -Throw
        }
        It 'Rejects invalid -Action value' {
            { Invoke-ComputerServiceControl -ComputerName 'localhost' -ServiceName 'spooler' -Action 'Pause' } |
                Should -Throw
        }
    }

    Context 'Service not found' {
        BeforeEach {
            Mock Get-CimInstance { $null }
        }
        It "Returns [!] when service name is not found on target" {
            $result = Invoke-ComputerServiceControl -ComputerName 'localhost' -ServiceName 'nonexistent' -Action 'Start'
            $result | Should -BeLike '*not found*'
        }
    }

    Context 'Start action' {
        BeforeAll {
            Mock Get-CimInstance { [PSCustomObject]@{ Name = 'spooler' } }
            Mock Invoke-CimMethod { [PSCustomObject]@{ ReturnValue = 0 } }
        }
        It 'Returns [OK] ... Started ... on success' {
            $result = Invoke-ComputerServiceControl -ComputerName 'localhost' -ServiceName 'spooler' -Action 'Start'
            $result | Should -Match '^\[OK\].*spooler.*Started'
        }
        It 'Calls StartService CIM method' {
            Mock Invoke-CimMethod { [PSCustomObject]@{ ReturnValue = 0 } }
            Invoke-ComputerServiceControl -ComputerName 'localhost' -ServiceName 'spooler' -Action 'Start' | Out-Null
            Should -Invoke Invoke-CimMethod -Times 1 -ParameterFilter { $MethodName -eq 'StartService' }
        }
    }

    Context 'Stop action' {
        BeforeAll {
            Mock Get-CimInstance { [PSCustomObject]@{ Name = 'spooler' } }
            Mock Invoke-CimMethod { [PSCustomObject]@{ ReturnValue = 0 } }
        }
        It 'Returns [OK] ... Stopped ... on success' {
            $result = Invoke-ComputerServiceControl -ComputerName 'localhost' -ServiceName 'spooler' -Action 'Stop'
            $result | Should -Match '^\[OK\].*spooler.*Stopped'
        }
        It 'Calls StopService CIM method' {
            Mock Invoke-CimMethod { [PSCustomObject]@{ ReturnValue = 0 } }
            Invoke-ComputerServiceControl -ComputerName 'localhost' -ServiceName 'spooler' -Action 'Stop' | Out-Null
            Should -Invoke Invoke-CimMethod -Times 1 -ParameterFilter { $MethodName -eq 'StopService' }
        }
    }

    Context 'Restart action' {
        BeforeAll {
            Mock Get-CimInstance { [PSCustomObject]@{ Name = 'spooler' } }
            Mock Invoke-CimMethod { [PSCustomObject]@{ ReturnValue = 0 } }
            Mock Start-Sleep { }
        }
        It 'Returns [OK] ... Restarted ... on success' {
            $result = Invoke-ComputerServiceControl -ComputerName 'localhost' -ServiceName 'spooler' -Action 'Restart'
            $result | Should -Match '^\[OK\].*spooler.*Restarted'
        }
        It 'Calls StopService then StartService in order' {
            $script:svcControlCalls = [System.Collections.Generic.List[string]]::new()
            Mock Invoke-CimMethod {
                $script:svcControlCalls.Add($MethodName)
                [PSCustomObject]@{ ReturnValue = 0 }
            }
            Mock Start-Sleep { }
            Invoke-ComputerServiceControl -ComputerName 'localhost' -ServiceName 'spooler' -Action 'Restart' | Out-Null
            $script:svcControlCalls[0] | Should -Be 'StopService'
            $script:svcControlCalls[1] | Should -Be 'StartService'
        }
        It 'Returns [!] if Stop returns non-zero during Restart' {
            Mock Invoke-CimMethod { [PSCustomObject]@{ ReturnValue = 5 } }
            $result = Invoke-ComputerServiceControl -ComputerName 'localhost' -ServiceName 'spooler' -Action 'Restart'
            $result | Should -BeLike '*Stop returned code 5*'
        }
    }

    Context 'Non-zero CIM return code' {
        BeforeAll {
            Mock Get-CimInstance { [PSCustomObject]@{ Name = 'spooler' } }
            Mock Invoke-CimMethod { [PSCustomObject]@{ ReturnValue = 2 } }
        }
        It 'Returns [!] with return code when action fails' {
            $result = Invoke-ComputerServiceControl -ComputerName 'localhost' -ServiceName 'spooler' -Action 'Start'
            $result | Should -BeLike '*returned code 2*'
        }
    }

    Context 'Error path — CIM throws' {
        BeforeEach {
            Mock Get-CimInstance { throw 'CIM connection error' }
        }
        It "Returns 'Error: ...' on CIM exception" {
            $result = Invoke-ComputerServiceControl -ComputerName 'localhost' -ServiceName 'spooler' -Action 'Start'
            $result | Should -BeLike 'Error:*'
        }
    }

    Context 'Local routing — $isLocal detection' {
        BeforeAll {
            Mock Get-CimInstance { [PSCustomObject]@{ Name = 'spooler' } }
            Mock Invoke-CimMethod { [PSCustomObject]@{ ReturnValue = 0 } }
        }
        It 'Omits ComputerName from Get-CimInstance for localhost' {
            Invoke-ComputerServiceControl -ComputerName 'localhost' -ServiceName 'spooler' -Action 'Start' | Out-Null
            Should -Invoke Get-CimInstance -Times 1 -ParameterFilter {
                -not $PSBoundParameters.ContainsKey('ComputerName')
            }
        }
        It 'Passes ComputerName to Get-CimInstance for remote targets' {
            Invoke-ComputerServiceControl -ComputerName 'REMOTEPC01' -ServiceName 'spooler' -Action 'Start' | Out-Null
            Should -Invoke Get-CimInstance -Times 1 -ParameterFilter { $ComputerName -eq 'REMOTEPC01' }
        }
    }
}
