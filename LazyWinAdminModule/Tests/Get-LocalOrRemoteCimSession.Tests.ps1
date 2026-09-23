BeforeAll {
    . $PSScriptRoot\..\Private\Get-LocalOrRemoteCimSession.ps1
}

Describe "Get-LocalOrRemoteCimSession" {
    It "reuses an existing CimSession if passed via -ReuseSession" {
        $remoteName = "Server1"
        $existingSession = New-CimSession -ErrorAction Stop
        try {
            Mock New-CimSession { throw 'A reused session must not be recreated' }
            $result = Get-LocalOrRemoteCimSession -ComputerName $remoteName -ReuseSession $existingSession
            $result | Should -Be $existingSession
            Should -Invoke New-CimSession -Times 0
        }
        finally {
            Remove-CimSession -CimSession $existingSession
        }
    }

    It "creates a local CimSession when ComputerName is localhost" {
        Mock New-CimSession { return "LocalSession" } -ParameterFilter { $null -eq $ComputerName }
        $result = Get-LocalOrRemoteCimSession -ComputerName "localhost"
        $result | Should -Be "LocalSession"
        Assert-MockCalled New-CimSession -Times 1 -ParameterFilter { $null -eq $ComputerName }
    }

    It "creates a remote CimSession when ComputerName is a remote server" {
        $remoteName = "Server1"
        Mock New-CimSession { return "RemoteSession" } -ParameterFilter { $ComputerName -eq "Server1" }
        $result = Get-LocalOrRemoteCimSession -ComputerName $remoteName
        $result | Should -Be "RemoteSession"
        Assert-MockCalled New-CimSession -Times 1 -ParameterFilter { $ComputerName -eq "Server1" }
    }
}
