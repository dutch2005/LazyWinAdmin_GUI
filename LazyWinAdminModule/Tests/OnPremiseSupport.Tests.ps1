Describe 'On-Premise Support Features' {
    BeforeAll {
        if (-not (Get-Command Get-LocalOrRemoteCimSession -ErrorAction SilentlyContinue)) { function Get-LocalOrRemoteCimSession { return $null } }
        . $PSScriptRoot\..\Public\Get-LWAComputerEventLog.ps1
        . $PSScriptRoot\..\Public\Get-LWAComputerVolume.ps1
        . $PSScriptRoot\..\Public\Get-LWAComputerSmbSession.ps1
        . $PSScriptRoot\..\Public\Close-LWAComputerSmbFile.ps1
        . $PSScriptRoot\..\Public\Get-LWAComputerUpdate.ps1
        . $PSScriptRoot\..\Public\Enter-LWAComputerSession.ps1
    }

    Context 'Get-LWAComputerEventLog' {
        It 'Invokes Get-WinEvent' {
            Mock Get-WinEvent { return [PSCustomObject]@{ Message = 'Test error' } }
            $result = Get-LWAComputerEventLog -ComputerName 'localhost'
            $result.Message | Should -Be 'Test error'
        }
    }

    Context 'Get-LWAComputerVolume' {
        It 'Invokes Get-CimInstance' {
            Mock Get-CimInstance { return [PSCustomObject]@{ DriveLetter = 'C' } }
            $result = Get-LWAComputerVolume
            $result.DriveLetter | Should -Be 'C'
        }
    }

    Context 'Get-LWAComputerSmbSession' {
        It 'Invokes Get-CimInstance' {
            Mock Get-CimInstance { return [PSCustomObject]@{ ClientComputerName = 'PC1' } }
            $result = Get-LWAComputerSmbSession
            $result.ClientComputerName | Should -Be 'PC1'
        }
    }

    Context 'Close-LWAComputerSmbFile' {
        It 'Invokes Invoke-CimMethod' {
            Mock Get-CimInstance { return [Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_SmbOpenFile') }
            Mock Invoke-CimMethod { }
            $result = Close-LWAComputerSmbFile -FileId 123
            $result | Should -Be $true
        }
    }

    Context 'Get-LWAComputerUpdate' {
        It 'Invokes Invoke-Command' {
            Mock Invoke-Command { return [PSCustomObject]@{ Title = 'Update 1' } }
            $result = Get-LWAComputerUpdate
            $result.Title | Should -Be 'Update 1'
        }
    }

    Context 'Enter-LWAComputerSession' {
        It 'Invokes Start-Process' {
            Mock Start-Process { return $true }
            { Enter-LWAComputerSession -ComputerName 'Server01' } | Should -Not -Throw
        }
    }
}
