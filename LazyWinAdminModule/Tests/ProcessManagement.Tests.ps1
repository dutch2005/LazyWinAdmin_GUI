Describe 'Process Management' {
    BeforeAll {
        if (-not (Get-Command Get-LocalOrRemoteCimSession -ErrorAction SilentlyContinue)) { function Get-LocalOrRemoteCimSession { return $null } }
        . $PSScriptRoot\..\Public\Get-LWAComputerProcess.ps1
        . $PSScriptRoot\..\Public\Stop-LWAComputerProcess.ps1
    }

    Context 'Get-LWAComputerProcess' {
        It 'Returns processes' {
            Mock Get-LocalOrRemoteCimSession { return $null }
            Mock Get-CimInstance { return [PSCustomObject]@{ ProcessId = 1234; Name = 'test.exe' } }
            
            $result = Get-LWAComputerProcess
            $result.ProcessId | Should -Be 1234
            $result.Name | Should -Be 'test.exe'
        }
    }

    Context 'Stop-LWAComputerProcess' {
        It 'Stops the process' {
            Mock Get-LocalOrRemoteCimSession { return $null }
            Mock Get-CimInstance { return [Microsoft.Management.Infrastructure.CimInstance]::new('Win32_Process') }
            Mock Invoke-CimMethod { }
            
            $result = Stop-LWAComputerProcess -ProcessId 1234
            $result | Should -Be $true
        }
    }
}
