$moduleRoot = (Item-Path (Join-Path $PSScriptRoot "..")).FullName
$functionPath = Join-Path $moduleRoot "Private\Get-ComputerUptime.ps1"
. $functionPath

Describe "Get-ComputerUptime" {
    Context "Mocking CIM" {
        Mock Get-CimInstance {
            return [PSCustomObject]@{
                LastBootUpTime = (Get-Date).AddDays(-5)
            }
        }

        It "Returns a string containing '5 days'" {
            $result = Get-ComputerUptime -ComputerName "localhost"
            $result | Should -Match "5 days"
        }
    }

    Context "Error Handling" {
        Mock Get-CimInstance { throw "CIM Error" }
        
        It "Returns null on error" {
            $result = Get-ComputerUptime -ComputerName "BadPC"
            $result | Should -BeNull
        }
    }
}