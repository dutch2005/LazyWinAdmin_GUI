#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingComputerNameHardcoded', '',
    Justification = 'Test fixtures require hardcoded computer names as test inputs.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Mock stub functions declare params to match real signatures.')]
param()

BeforeAll {
    $script:ModuleRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    Get-ChildItem (Join-Path $script:ModuleRoot 'Classes') -Filter '*.ps1' | ForEach-Object { . $_.FullName }
    Get-ChildItem (Join-Path $script:ModuleRoot 'Private') -Filter '*.ps1' | ForEach-Object { . $_.FullName }
    Get-ChildItem (Join-Path $script:ModuleRoot 'Public')  -Filter '*.ps1' | ForEach-Object { . $_.FullName }

    # Fake WaitHandle — WaitOne just needs to not throw; result is piped to Out-Null
    $script:FakeWaitHandle = [PSCustomObject]@{}
    $script:FakeWaitHandle | Add-Member -MemberType ScriptMethod -Name 'WaitOne' -Value { param($ms, $exit) $true }

    $script:FakeAsyncResult = [PSCustomObject]@{ AsyncWaitHandle = $script:FakeWaitHandle }

    # Open TcpClient
    $script:FakeTcpOpen = [PSCustomObject]@{ Connected = $true }
    $script:FakeTcpOpen | Add-Member -MemberType ScriptMethod -Name 'BeginConnect' -Value { param($h,$p,$cb,$s) $script:FakeAsyncResult }
    $script:FakeTcpOpen | Add-Member -MemberType ScriptMethod -Name 'EndConnect'   -Value { param($r) }
    $script:FakeTcpOpen | Add-Member -MemberType ScriptMethod -Name 'Dispose'      -Value { }

    # Closed TcpClient
    $script:FakeTcpClosed = [PSCustomObject]@{ Connected = $false }
    $script:FakeTcpClosed | Add-Member -MemberType ScriptMethod -Name 'BeginConnect' -Value { param($h,$p,$cb,$s) $script:FakeAsyncResult }
    $script:FakeTcpClosed | Add-Member -MemberType ScriptMethod -Name 'EndConnect'   -Value { param($r) }
    $script:FakeTcpClosed | Add-Member -MemberType ScriptMethod -Name 'Dispose'      -Value { }
}

Describe 'Test-ComputerPort' {

    Context 'Parameter validation' {

        It 'ComputerName is mandatory — throws without it' {
            { Test-ComputerPort } | Should -Throw
        }

        It 'Accepts ComputerName with default Port and TimeoutMs' {
            Mock New-Object { $script:FakeTcpClosed } -ParameterFilter { $TypeName -eq 'System.Net.Sockets.TcpClient' }
            { Test-ComputerPort -ComputerName 'localhost' } | Should -Not -Throw
        }
    }

    Context 'Open port path' {

        BeforeAll {
            Mock New-Object { $script:FakeTcpOpen } -ParameterFilter { $TypeName -eq 'System.Net.Sockets.TcpClient' }
        }

        It 'Returns "Open" when TCP client connects successfully' {
            $result = Test-ComputerPort -ComputerName 'localhost' -Port 80
            $result | Should -Be 'Open'
        }
    }

    Context 'Closed/filtered port path' {

        BeforeAll {
            Mock New-Object { $script:FakeTcpClosed } -ParameterFilter { $TypeName -eq 'System.Net.Sockets.TcpClient' }
        }

        It 'Returns "Closed/Filtered" when TCP client does not connect' {
            $result = Test-ComputerPort -ComputerName 'localhost' -Port 9999
            $result | Should -Be 'Closed/Filtered'
        }
    }

    Context 'Error path' {

        BeforeAll {
            Mock New-Object { throw 'Simulated socket error' } -ParameterFilter { $TypeName -eq 'System.Net.Sockets.TcpClient' }
        }

        It 'Returns "Error" when New-Object throws' {
            $result = Test-ComputerPort -ComputerName 'unreachable-host' -Port 80
            $result | Should -Be 'Error'
        }
    }

    Context 'Dispose is called' {

        It 'Calls Dispose on the TcpClient even when connected (open path)' {
            $script:DisposeCallCount = 0
            $script:FakeTcpDisposeTest = [PSCustomObject]@{ Connected = $true }
            $script:FakeTcpDisposeTest | Add-Member -MemberType ScriptMethod -Name 'BeginConnect' -Value { param($h,$p,$cb,$s) $script:FakeAsyncResult }
            $script:FakeTcpDisposeTest | Add-Member -MemberType ScriptMethod -Name 'EndConnect'   -Value { param($r) }
            $script:FakeTcpDisposeTest | Add-Member -MemberType ScriptMethod -Name 'Dispose'      -Value { $script:DisposeCallCount++ }

            Mock New-Object { $script:FakeTcpDisposeTest } -ParameterFilter { $TypeName -eq 'System.Net.Sockets.TcpClient' }
            Test-ComputerPort -ComputerName 'localhost' -Port 80 | Out-Null
            $script:DisposeCallCount | Should -Be 1
        }

        It 'Calls Dispose on the TcpClient even when closed (error path)' {
            $script:DisposeCallCount2 = 0
            $script:FakeTcpDisposeTest2 = [PSCustomObject]@{ Connected = $false }
            $script:FakeTcpDisposeTest2 | Add-Member -MemberType ScriptMethod -Name 'BeginConnect' -Value { param($h,$p,$cb,$s) $script:FakeAsyncResult }
            $script:FakeTcpDisposeTest2 | Add-Member -MemberType ScriptMethod -Name 'EndConnect'   -Value { param($r) }
            $script:FakeTcpDisposeTest2 | Add-Member -MemberType ScriptMethod -Name 'Dispose'      -Value { $script:DisposeCallCount2++ }

            Mock New-Object { $script:FakeTcpDisposeTest2 } -ParameterFilter { $TypeName -eq 'System.Net.Sockets.TcpClient' }
            Test-ComputerPort -ComputerName 'localhost' -Port 9999 | Out-Null
            $script:DisposeCallCount2 | Should -Be 1
        }
    }
}