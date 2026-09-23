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

Describe 'Helpdesk handler behavior' {
    BeforeAll {
        Set-Item -Path Function:Restart-LWAComputer -Value { param($ComputerName) $ComputerName }
        $script:Controls = @{}
        $names = @(
            'btnGetLaps', 'btnStartRdp', 'btnQuickAssist', 'btnRestartComputer',
            'btnRemoteCommand', 'btnGpUpdate', 'btnFlushDns',
            'btnUninstallSoftware', 'btnForceUpdates', 'btnSendPopup',
            'btnGetPrinter', 'btnRestartSpooler', 'btnForceLogoff',
            'btnLockWorkstation', 'btnUnlockAd', 'btnResetAdPassword',
            'btnEntraSync', 'btnSetTenant', 'btnMessageTrace',
            'btnMailboxStats', 'btnExchangeBlockDomain', 'btnGetAutoReply'
        )
        foreach ($name in $names) {
            $control = [pscustomobject]@{
                Handlers = [System.Collections.Generic.List[scriptblock]]::new()
            }
            $control | Add-Member -MemberType ScriptMethod -Name Add_Click -Value {
                param([scriptblock]$Handler)
                $this.Handlers.Add($Handler)
            }
            $script:Controls[$name] = $control
            Set-Variable -Name $name -Value $control -Scope Script
        }
        $script:txtHelpdeskTarget = [pscustomobject]@{ Text = '' }
        $script:txtHelpdeskOutput = [pscustomobject]@{ Text = '' }
        $script:UiHandlerPath = Split-Path $script:CompositionPath
        . $script:CompositionPath
    }

    It 'registers one live click handler per Helpdesk button' {
        foreach ($control in $script:Controls.Values) {
            $control.Handlers.Count | Should -Be 1
        }
    }

    It 'rejects an empty computer target without running the action' {
        $script:txtHelpdeskTarget.Text = ' '
        $script:txtHelpdeskOutput.Text = ''
        Mock Restart-LWAComputer { throw 'Action must not run' }
        & $script:Controls['btnRestartComputer'].Handlers[0]
        Should -Invoke Restart-LWAComputer -Times 0
        $script:txtHelpdeskOutput.Text | Should -Match 'Please specify a target computer'
    }

    It 'routes a computer target to the original restart command' {
        $script:txtHelpdeskTarget.Text = 'PC-01'
        $script:txtHelpdeskOutput.Text = ''
        Mock Restart-LWAComputer { 'Restart requested' }
        & $script:Controls['btnRestartComputer'].Handlers[0]
        Should -Invoke Restart-LWAComputer -Times 1 -ParameterFilter {
            $ComputerName -eq 'PC-01'
        }
        $script:txtHelpdeskOutput.Text | Should -Match 'Restart requested'
    }

    It 'keeps the password reset as a placeholder' {
        $script:txtHelpdeskTarget.Text = 'alice'
        $script:txtHelpdeskOutput.Text = ''
        & $script:Controls['btnResetAdPassword'].Handlers[0]
        $script:txtHelpdeskOutput.Text | Should -Match 'securely prompting'
    }
}
