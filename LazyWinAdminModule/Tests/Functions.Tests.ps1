# Dot-source all module files for testing to ensure isolation and compatibility
$ModuleRoot = Resolve-Path (Join-Path $PSScriptRoot "..\")
Get-ChildItem (Join-Path $ModuleRoot "Classes") -Filter "*.ps1" | ForEach-Object { . $_.FullName }
Get-ChildItem (Join-Path $ModuleRoot "Private") -Filter "*.ps1" | ForEach-Object { . $_.FullName }
Get-ChildItem (Join-Path $ModuleRoot "Public") -Filter "*.ps1" | ForEach-Object { . $_.FullName }

Describe "Private Function Logic" {
    Context "Get-ComputerService" {
        It "Should return service objects when mocked" {
            # Mock the Get-CimInstance call
            Mock Get-CimInstance {
                return [PSCustomObject]@{
                    Name = "TestService"
                    DisplayName = "Test Service"
                    State = "Running"
                    StartMode = "Auto"
                    StartName = "LocalSystem"
                }
            } -ParameterFilter { $ClassName -eq 'Win32_Service' }

            $results = Get-ComputerService -ComputerName "localhost"
            $results | Should Not Be $null
            $results.Name | Should Be "TestService"
        }
    }

    Context "Get-ComputerHardware" {
        It "Should return hardware summary when mocked" {
            Mock Get-CimInstance {
                param($ClassName)
                switch ($ClassName) {
                    'Win32_ComputerSystem' { return [PSCustomObject]@{ Manufacturer = "Dell"; Model = "XPS" } }
                    'Win32_Processor' { return [PSCustomObject]@{ Name = "Intel i7"; NumberOfCores = 8 } }
                    'Win32_OperatingSystem' { return [PSCustomObject]@{ Caption = "Windows 11"; TotalVisibleMemorySize = 16777216 } }
                    'Win32_Bios' { return [PSCustomObject]@{ SerialNumber = "12345" } }
                    'Win32_PhysicalMemory' { return [PSCustomObject]@{ Capacity = 16GB } }
                    'Win32_LogicalDisk' { return [PSCustomObject]@{ DeviceID = "C:"; Size = 100GB; FreeSpace = 50GB } }
                }
            }

            $result = Get-ComputerHardware -ComputerName "localhost"
            $result.Manufacturer | Should Be "Dell"
            $result.CPU | Should Match "Intel i7"
            $result.RAM_GB | Should Be 16
        }
    }

    Context "Registry Operations" {
        It "Should throw on invalid actions in Invoke-ComputerRegistry" {
            { Invoke-ComputerRegistry -Action "Invalid" } | Should Throw
        }
    }
}
