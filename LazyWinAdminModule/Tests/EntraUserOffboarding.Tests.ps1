#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Mock stub functions declare params to match real cmdlet signatures.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseShouldProcessForStateChangingFunctions', '',
    Justification = 'Stub functions emulate real Graph cmdlet names for mocking; they perform no work.')]
param()

BeforeAll {
    $script:ModuleRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    Get-ChildItem (Join-Path $script:ModuleRoot 'Classes') -Filter '*.ps1' | ForEach-Object { . $_.FullName }
    Get-ChildItem (Join-Path $script:ModuleRoot 'Private') -Filter '*.ps1' | ForEach-Object { . $_.FullName }
    Get-ChildItem (Join-Path $script:ModuleRoot 'Public')  -Filter '*.ps1' | ForEach-Object { . $_.FullName }

    if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue)) {
        function Get-MgContext { }
    }
    if (-not (Get-Command Update-MgUser -ErrorAction SilentlyContinue)) {
        function Update-MgUser { param([string]$UserId, [bool]$AccountEnabled) }
    }
    if (-not (Get-Command Get-MgUser -ErrorAction SilentlyContinue)) {
        function Get-MgUser { param([string]$UserId) }
    }
}

Describe 'Set-EntraUserAccountState' {

    Context 'Guard - not connected' {
        BeforeAll { Mock Get-MgContext { $null } }
        It 'Returns [!] without calling Update-MgUser' {
            Mock Update-MgUser { }
            $r = Set-EntraUserAccountState -UserPrincipalName 'u@t.com' -Enabled $false
            $r | Should -Match '^\[!\]'
            Should -Invoke Update-MgUser -Times 0
        }
    }

    Context 'Block sign-in' {
        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } }
            Mock Update-MgUser { }
        }
        It 'Disables the account and reports blocked' {
            $r = Set-EntraUserAccountState -UserPrincipalName 'u@t.com' -Enabled $false
            $r | Should -BeLike '*blocked*'
            Should -Invoke Update-MgUser -Times 1 -Exactly -ParameterFilter { $AccountEnabled -eq $false }
        }
    }

    Context 'Enable sign-in' {
        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } }
            Mock Update-MgUser { }
        }
        It 'Enables the account and reports enabled' {
            $r = Set-EntraUserAccountState -UserPrincipalName 'u@t.com' -Enabled $true
            $r | Should -BeLike '*enabled*'
            Should -Invoke Update-MgUser -Times 1 -Exactly -ParameterFilter { $AccountEnabled -eq $true }
        }
    }
}

Describe 'Invoke-EntraUserOffboarding' {

    Context 'No steps selected' {
        It 'Returns a single No-action entry' {
            $report = @(Invoke-EntraUserOffboarding -UserPrincipalName 'u@t.com')
            $report.Count      | Should -Be 1
            $report[0].Result  | Should -BeLike '*No offboarding steps*'
        }
    }

    Context 'WhatIf dry run' {
        BeforeAll { Mock Set-EntraUserAccountState { '[OK] Sign-in blocked for u@t.com' } }
        It 'Returns a single dry-run line and executes no steps' {
            $report = @(Invoke-EntraUserOffboarding -UserPrincipalName 'u@t.com' -BlockSignIn -WhatIf)
            $report.Count   | Should -Be 1
            $report[0].Step | Should -Be 'Dry run'
            Should -Invoke Set-EntraUserAccountState -Times 0
        }
    }

    Context 'Only selected steps run, in order' {
        BeforeAll {
            Mock Set-EntraUserAccountState { '[OK] Sign-in blocked for u@t.com' }
            Mock Revoke-EntraUserSession  { '[OK] Revoked all sign-in sessions' }
        }
        It 'Runs block sign-in then revoke, and nothing else' {
            $report = @(Invoke-EntraUserOffboarding -UserPrincipalName 'u@t.com' -BlockSignIn -RevokeSessions)
            $report.Count       | Should -Be 2
            $report[0].Step     | Should -Be 'Block sign-in'
            $report[1].Step     | Should -Be 'Revoke sessions'
            Should -Invoke Set-EntraUserAccountState -Times 1 -Exactly
            Should -Invoke Revoke-EntraUserSession  -Times 1 -Exactly
        }
    }

    Context 'Reset password never leaks the value into the report' {
        BeforeAll {
            Mock Set-EntraUserPassword {
                [PSCustomObject]@{ Status = '[OK] Password reset for u@t.com'; Password = 'S3cretValue!' }
            }
        }
        It 'Records the status but not the password' {
            $report = @(Invoke-EntraUserOffboarding -UserPrincipalName 'u@t.com' -ResetPassword)
            $step   = $report | Where-Object { $_.Step -eq 'Reset password' }
            $step.Result | Should -Match '^\[OK\]'
            $step.Result | Should -Not -Match 'S3cretValue'
        }
    }

    Context 'A failing step is recorded and the rest still run' {
        BeforeAll {
            Mock Set-EntraUserAccountState { '[!] Account state update failed.' }
            Mock Revoke-EntraUserSession  { '[OK] Revoked all sign-in sessions' }
        }
        It 'Continues past a failed step' {
            $report = @(Invoke-EntraUserOffboarding -UserPrincipalName 'u@t.com' -BlockSignIn -RevokeSessions)
            $report.Count | Should -Be 2
            ($report | Where-Object { $_.Step -eq 'Block sign-in' }).Result   | Should -Match '\[!\]'
            ($report | Where-Object { $_.Step -eq 'Revoke sessions' }).Result | Should -Match '\[OK\]'
        }
    }

    Context 'Remove from groups resolves object id and removes each membership' {
        BeforeAll {
            Mock Get-MgUser { [PSCustomObject]@{ Id = 'user-oid' } }
            Mock Get-EntraUserMembership { [PSCustomObject]@{ DisplayName = 'Sales'; Id = 'group-1'; Type = 'group' } }
            Mock Set-EntraGroupMembership { '[OK] Remove membership for user-oid on group group-1' }
        }
        It 'Removes the user from the group by object id' {
            $report = @(Invoke-EntraUserOffboarding -UserPrincipalName 'u@t.com' -RemoveFromGroups)
            Should -Invoke Set-EntraGroupMembership -Times 1 -Exactly -ParameterFilter {
                $GroupId -eq 'group-1' -and $UserId -eq 'user-oid' -and $Action -eq 'Remove'
            }
            ($report | Where-Object { $_.Step -like 'Remove from group*' }) | Should -Not -BeNullOrEmpty
        }
    }
}
