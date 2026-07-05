BeforeAll {
    . $PSScriptRoot\..\Private\Get-LocalOrRemoteCimSession.ps1
}

Describe "Get-LocalOrRemoteCimSession" {
    It "reuses an existing CimSession if passed via -ReuseSession" {
        $mockSession = [Microsoft.Management.Infrastructure.CimSession]::new()
        $result = Get-LocalOrRemoteCimSession -ComputerName "Server1" -ReuseSession $mockSession
        $result | Should -Be $mockSession
    }

    It "creates a local CimSession when ComputerName is localhost" {
        Mock New-CimSession { return "LocalSession" } -ParameterFilter { $null -eq $ComputerName }
        $result = Get-LocalOrRemoteCimSession -ComputerName "localhost"
        $result | Should -Be "LocalSession"
        Assert-MockCalled New-CimSession -Times 1 -ParameterFilter { $null -eq $ComputerName }
    }

    It "creates a remote CimSession when ComputerName is a remote server" {
        Mock New-CimSession { return "RemoteSession" } -ParameterFilter { $ComputerName -eq "Server1" }
        $result = Get-LocalOrRemoteCimSession -ComputerName "Server1"
        $result | Should -Be "RemoteSession"
        Assert-MockCalled New-CimSession -Times 1 -ParameterFilter { $ComputerName -eq "Server1" }
    }
}
