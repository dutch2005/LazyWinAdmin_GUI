# Dot-source all module files for testing to ensure isolation and compatibility
$ModuleRoot = Resolve-Path (Join-Path $PSScriptRoot "..\")
Get-ChildItem (Join-Path $ModuleRoot "Classes") -Filter "*.ps1" | ForEach-Object { . $_.FullName }
Get-ChildItem (Join-Path $ModuleRoot "Private") -Filter "*.ps1" | ForEach-Object { . $_.FullName }
Get-ChildItem (Join-Path $ModuleRoot "Public") -Filter "*.ps1" | ForEach-Object { . $_.FullName }

Describe "LazyWinAdmin Module Integrity" {
    Context "Application State" {
        It "Should initialize the LazyWinAdminState class" {
            $state = [LazyWinAdminState]::new()
            $state | Should Not Be $null
            $state.SyncHash | Should Not Be $null
            $state.RunspacePool | Should Not Be $null
            $state.Dispose()
        }

        It "Should log messages to the SyncHash" {
            $state = [LazyWinAdminState]::new()
            $state.Log("Test Message")
            $state.SyncHash.Logs.Count | Should BeGreaterThan 0
            $state.SyncHash.Logs[0] | Should Match "Test Message"
            $state.Dispose()
        }
    }

    Context "UI Resources" {
        It "Should have a valid MainView.xaml file" {
            $xamlPath = Join-Path $ModuleRoot "UI\MainView.xaml"
            Test-Path $xamlPath | Should Be $true
        }

        It "Should be able to load the XAML into an XmlDocument" {
            $xamlPath = Join-Path $ModuleRoot "UI\MainView.xaml"
            $xamlContent = Get-Content $xamlPath -Raw
            $xmlDoc = [System.Xml.XmlDocument]::new()
            { $xmlDoc.LoadXml($xamlContent) } | Should Not Throw
        }
    }

    Context "Public Functions" {
        It "Should export Start-LazyWinAdmin" {
            (Get-Command Start-LazyWinAdmin -ErrorAction SilentlyContinue) | Should Not Be $null
        }
    }
}
