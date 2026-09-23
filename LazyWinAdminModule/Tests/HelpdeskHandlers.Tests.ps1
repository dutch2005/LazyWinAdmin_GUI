#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

BeforeAll {
    $script:ModuleRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:CompositionPath = Join-Path $script:ModuleRoot 'UI\Handlers\Register-HelpdeskHandlers.ps1'
    $script:HelpdeskPath = Join-Path $script:ModuleRoot 'UI\Handlers\Helpdesk'
    $script:HandlerFiles = @(
        $script:CompositionPath
        (Join-Path $script:HelpdeskPath 'Initialize-HelpdeskHelpers.ps1')
        (Join-Path $script:HelpdeskPath 'Register-HelpdeskEndpointHandlers.ps1')
        (Join-Path $script:HelpdeskPath 'Register-HelpdeskSessionHandlers.ps1')
        (Join-Path $script:HelpdeskPath 'Register-HelpdeskIdentityHandlers.ps1')
        (Join-Path $script:HelpdeskPath 'Register-HelpdeskExchangeHandlers.ps1')
    )
}

Describe 'Helpdesk handler integrity' {
    It 'all expected handler files exist' -TestCases @(
        @{ Name = 'Register-HelpdeskHandlers.ps1' }
        @{ Name = 'Initialize-HelpdeskHelpers.ps1' }
        @{ Name = 'Register-HelpdeskEndpointHandlers.ps1' }
        @{ Name = 'Register-HelpdeskSessionHandlers.ps1' }
        @{ Name = 'Register-HelpdeskIdentityHandlers.ps1' }
        @{ Name = 'Register-HelpdeskExchangeHandlers.ps1' }
    ) {
        param($Name)
        $path = if ($Name -eq 'Register-HelpdeskHandlers.ps1') {
            $script:CompositionPath
        } else {
            Join-Path $script:HelpdeskPath $Name
        }
        $path | Should -Exist
    }

    It 'every Helpdesk production file is 200 lines or fewer' -TestCases @(
        @{ Index = 0 }; @{ Index = 1 }; @{ Index = 2 }
        @{ Index = 3 }; @{ Index = 4 }; @{ Index = 5 }
    ) {
        param($Index)
        (Get-Content $script:HandlerFiles[$Index]).Count | Should -BeLessOrEqual 200
    }

    It 'every Helpdesk handler file parses without errors' -TestCases @(
        @{ Index = 0 }; @{ Index = 1 }; @{ Index = 2 }
        @{ Index = 3 }; @{ Index = 4 }; @{ Index = 5 }
    ) {
        param($Index)
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            $script:HandlerFiles[$Index],
            [ref]$tokens,
            [ref]$errors
        ) | Out-Null
        $errors.Count | Should -Be 0
    }

    It 'composition script imports every handler group' {
        $content = Get-Content $script:CompositionPath -Raw
        $content | Should -Match 'Initialize-HelpdeskHelpers\.ps1'
        $content | Should -Match 'Register-HelpdeskEndpointHandlers\.ps1'
        $content | Should -Match 'Register-HelpdeskSessionHandlers\.ps1'
        $content | Should -Match 'Register-HelpdeskIdentityHandlers\.ps1'
        $content | Should -Match 'Register-HelpdeskExchangeHandlers\.ps1'
    }

    It 'registers each Helpdesk button exactly once' -TestCases @(
        @{ Control = 'btnGetLaps' }
        @{ Control = 'btnStartRdp' }
        @{ Control = 'btnQuickAssist' }
        @{ Control = 'btnRestartComputer' }
        @{ Control = 'btnRemoteCommand' }
        @{ Control = 'btnGpUpdate' }
        @{ Control = 'btnFlushDns' }
        @{ Control = 'btnUninstallSoftware' }
        @{ Control = 'btnForceUpdates' }
        @{ Control = 'btnSendPopup' }
        @{ Control = 'btnGetPrinter' }
        @{ Control = 'btnRestartSpooler' }
        @{ Control = 'btnForceLogoff' }
        @{ Control = 'btnLockWorkstation' }
        @{ Control = 'btnUnlockAd' }
        @{ Control = 'btnResetAdPassword' }
        @{ Control = 'btnEntraSync' }
        @{ Control = 'btnSetTenant' }
        @{ Control = 'btnMessageTrace' }
        @{ Control = 'btnMailboxStats' }
        @{ Control = 'btnExchangeBlockDomain' }
        @{ Control = 'btnGetAutoReply' }
    ) {
        param($Control)
        $content = (
            Get-ChildItem $script:HelpdeskPath -Filter '*.ps1' |
                Get-Content -Raw
        ) -join [Environment]::NewLine
        $pattern = [regex]::Escape('$' + $Control + '.Add_Click')
        ([regex]::Matches($content, $pattern)).Count | Should -Be 1
    }
}
