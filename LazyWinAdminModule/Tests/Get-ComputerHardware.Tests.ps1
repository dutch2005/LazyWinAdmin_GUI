$moduleRoot = (Item-Path (Join-Path $PSScriptRoot "..")).FullName
$functionPath = Join-Path $moduleRoot "Private\Get-ComputerHardware.ps1"
. $functionPath

Describe "Get-ComputerHardware" {
    Context "Mocking multiple CIM classes" {
        Mock Get-CimInstance {
            param($ClassName)
            switch ($ClassName) {
                "Win32_ComputerSystem" { return [PSCustomObject]@{ Model = "Precision 5570"; Manufacturer = "Dell" } }
                "Win32_OperatingSystem" { return [PSCustomObject]@{ Caption = "Microsoft Windows 11 Pro"; Version = "10.0.22631" } }
                "Win32_Bios" { return [PSCustomObject]@{ SerialNumber = "ABC1234" } }
                "Win32_Processor" { return @([PSCustomObject]@{ Name = "Intel i7"; NumberOfCores = 14 }) }
                "Win32_PhysicalMemory" { return @([PSCustomObject]@{ Capacity = 16GB }, [PSCustomObject]@{ Capacity = 16GB }) }
                "Win32_LogicalDisk" { return @([PSCustomObject]@{ DeviceID = "C:"; Size = 100GB; FreeSpace = 20GB }) }
            }
        }

        It "Returns a populated hardware object" {
            $res = Get-ComputerHardware -ComputerName "localhost"
            $res.Model | Should -Be "Precision 5570"
            $res.RAM_GB | Should -Be 32
            $res.SerialNumber | Should -Be "ABC1234"
            $res.Disks.Count | Should -Be 1
            $res.Disks[0].DeviceID | Should -Be "C:"
        }
    }
}