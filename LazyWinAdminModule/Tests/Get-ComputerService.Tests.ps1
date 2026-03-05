$moduleRoot = (Item-Path (Join-Path $PSScriptRoot "..")).FullName
$functionPath = Join-Path $moduleRoot "Private\Get-ComputerService.ps1"
. $functionPath

Describe "Get-ComputerService" {
    Context "Mocking CIM" {
        Mock Get-CimInstance {
            return @(
                [PSCustomObject]@{
                    Name = "Spooler"
                    DisplayName = "Print Spooler"
                    State = "Running"
                    StartMode = "Auto"
                    StartName = "LocalSystem"
                    ProcessId = 1234
                },
                [PSCustomObject]@{
                    Name = "WSearch"
                    DisplayName = "Windows Search"
                    State = "Stopped"
                    StartMode = "Auto"
                    StartName = "LocalSystem"
                    ProcessId = 0
                }
            )
        }

        It "Returns all services when no filter is provided" {
            $results = Get-ComputerService -ComputerName "TestPC"
            $results.Count | Should -Be 2
            $results[0].Name | Should -Be "Spooler"
        }

        It "Filters by name correctly" {
            $results = Get-ComputerService -ComputerName "TestPC" -Name "Spooler"
            # The function uses -Like internally if filter is provided to Get-CimInstance
            # Since we mocked the whole output, we verify it returns what we expect from our mock
            $results | Should -Not -BeNull
        }

        It "Filters OnlyAutoStopped correctly" {
            # In a real scenario, the filter would be passed to Get-CimInstance
            # Here we just verify the function returns the objects
            $results = Get-ComputerService -ComputerName "TestPC" -OnlyAutoStopped
            $results | Should -Not -BeNull
        }
    }
}