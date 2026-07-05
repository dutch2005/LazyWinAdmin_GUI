#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
param()

BeforeAll {
    $script:ModuleRoot   = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:HandlersDir  = Join-Path $script:ModuleRoot 'UI\Handlers'
    $script:StartScript  = Join-Path $script:ModuleRoot 'Public\Start-LazyWinAdmin.ps1'
}

Describe 'UI/Handlers section files' {

    It 'has a Handlers directory with section files' {
        Test-Path $script:HandlersDir | Should -BeTrue
        (Get-ChildItem $script:HandlersDir -Filter '*.ps1').Count | Should -BeGreaterThan 0
    }

    It 'every section file parses without syntax errors: <Name>' -ForEach @(
        Get-ChildItem (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'UI\Handlers') -Filter '*.ps1' |
            ForEach-Object { @{ Name = $_.Name; Path = $_.FullName } }
    ) {
        $errs = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$errs)
        @($errs).Count | Should -Be 0
    }

    It 'Start-LazyWinAdmin.ps1 parses without syntax errors' {
        $errs = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($script:StartScript, [ref]$null, [ref]$errs)
        @($errs).Count | Should -Be 0
    }
}

Describe 'Start-LazyWinAdmin orchestration' {

    BeforeAll { $script:StartText = Get-Content $script:StartScript -Raw }

    It 'is now a thin orchestrator (under 200 lines)' {
        (Get-Content $script:StartScript | Measure-Object -Line).Lines | Should -BeLessThan 200
    }

    It 'dot-sources each section file, and each referenced file exists' {
        $referenced = [regex]::Matches($script:StartText, "Join-Path \`$UiHandlerPath '([^']+\.ps1)'") |
                      ForEach-Object { $_.Groups[1].Value }
        $referenced.Count | Should -BeGreaterThan 5
        foreach ($file in $referenced) {
            Test-Path (Join-Path $script:HandlersDir $file) | Should -BeTrue -Because "$file is dot-sourced but missing"
        }
    }

    It 'dot-sources Find-Controls before Initialize-Helpers before the Register handlers' {
        $idxFind    = $script:StartText.IndexOf('Find-Controls.ps1')
        $idxHelpers = $script:StartText.IndexOf('Initialize-Helpers.ps1')
        $idxSystem  = $script:StartText.IndexOf('Register-SystemServiceHandlers.ps1')
        $idxFind    | Should -BeGreaterThan 0
        $idxHelpers | Should -BeGreaterThan $idxFind
        $idxSystem  | Should -BeGreaterThan $idxHelpers
    }
}

Describe 'Module loader isolation' {

    It 'does not auto-load the dot-sourced sections (they are in a subfolder, not UI top level)' {
        # The .psm1 globs UI/*.ps1 non-recursively; the sections live in UI/Handlers/
        (Get-ChildItem (Join-Path $script:ModuleRoot 'UI') -Filter '*.ps1').Count | Should -Be 0
    }
}
