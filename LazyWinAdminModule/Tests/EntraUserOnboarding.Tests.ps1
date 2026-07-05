#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Mock stub functions declare params to match real cmdlet signatures.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseShouldProcessForStateChangingFunctions', '',
    Justification = 'Stub functions emulate real Graph cmdlet names for mocking; they perform no work.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingPlainTextForPassword', '',
    Justification = 'New-MgUser stub mirrors the real cmdlet signature for mocking; no password is stored or transmitted.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingUsernameAndPasswordParams', '',
    Justification = 'New-MgUser stub mirrors the real cmdlet signature for mocking; no credential is handled.')]
param()

BeforeAll {
    $script:ModuleRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    Get-ChildItem (Join-Path $script:ModuleRoot 'Classes') -Filter '*.ps1' | ForEach-Object { . $_.FullName }
    Get-ChildItem (Join-Path $script:ModuleRoot 'Private') -Filter '*.ps1' | ForEach-Object { . $_.FullName }
    Get-ChildItem (Join-Path $script:ModuleRoot 'Public')  -Filter '*.ps1' | ForEach-Object { . $_.FullName }

    if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue)) {
        function Get-MgContext { }
    }
    if (-not (Get-Command New-MgUser -ErrorAction SilentlyContinue)) {
        function New-MgUser { param([bool]$AccountEnabled, [string]$DisplayName, [string]$UserPrincipalName, [string]$MailNickname, $PasswordProfile) }
    }
    if (-not (Get-Command Set-MgUserManagerByRef -ErrorAction SilentlyContinue)) {
        function Set-MgUserManagerByRef { param([string]$UserId, $BodyParameter) }
    }
}

Describe 'New-EntraUser' {

    Context 'Guard - not connected' {
        BeforeAll { Mock Get-MgContext { $null } }
        It 'Returns [!] status and null ids without calling New-MgUser' {
            Mock New-MgUser { }
            $r = New-EntraUser -DisplayName 'Jane Doe' -UserPrincipalName 'jane@t.com'
            $r.Status | Should -Match '^\[!\]'
            $r.UserId | Should -BeNullOrEmpty
            Should -Invoke New-MgUser -Times 0
        }
    }

    Context 'Success' {
        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } }
            Mock New-MgUser { [PSCustomObject]@{ Id = 'new-oid' } }
        }
        It 'Creates the user, forces password change, returns id + password' {
            $r = New-EntraUser -DisplayName 'Jane Doe' -UserPrincipalName 'jane@t.com'
            $r.Status   | Should -Match '^\[OK\]'
            $r.UserId   | Should -Be 'new-oid'
            $r.Password | Should -Not -BeNullOrEmpty
            Should -Invoke New-MgUser -Times 1 -Exactly -ParameterFilter {
                $UserPrincipalName -eq 'jane@t.com' -and $PasswordProfile.ForceChangePasswordNextSignIn -eq $true
            }
        }
        It 'Never puts the password into the status string' {
            $r = New-EntraUser -DisplayName 'Jane Doe' -UserPrincipalName 'jane@t.com'
            $r.Status | Should -Not -BeLike "*$($r.Password)*"
        }
    }

    Context 'Failure' {
        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } }
            Mock New-MgUser { throw 'A user with this UPN already exists' }
        }
        It 'Returns sanitised [!] and null ids' {
            $r = New-EntraUser -DisplayName 'Jane Doe' -UserPrincipalName 'jane@t.com'
            $r.Status | Should -Match '^\[!\]'
            $r.Status | Should -Not -Match 'already exists'
            $r.UserId | Should -BeNullOrEmpty
        }
    }
}

Describe 'Set-EntraUserManager' {

    Context 'Guard - not connected' {
        BeforeAll { Mock Get-MgContext { $null } }
        It 'Returns [!] without calling the cmdlet' {
            Mock Set-MgUserManagerByRef { }
            (Set-EntraUserManager -UserId 'u' -ManagerId 'm') | Should -Match '^\[!\]'
            Should -Invoke Set-MgUserManagerByRef -Times 0
        }
    }

    Context 'Success' {
        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } }
            Mock Set-MgUserManagerByRef { }
        }
        It 'References the manager object id in the odata body' {
            $r = Set-EntraUserManager -UserId 'user-oid' -ManagerId 'mgr-oid'
            $r | Should -Match '^\[OK\]'
            Should -Invoke Set-MgUserManagerByRef -Times 1 -Exactly -ParameterFilter {
                $UserId -eq 'user-oid' -and $BodyParameter['@odata.id'] -like '*mgr-oid'
            }
        }
    }
}

Describe 'Invoke-EntraUserOnboarding' {

    Context 'WhatIf dry run' {
        BeforeAll { Mock New-EntraUser { [PSCustomObject]@{ Status = '[OK]'; Password = 'x'; UserId = 'oid' } } }
        It 'Returns a dry-run step and creates nothing' {
            $r = Invoke-EntraUserOnboarding -DisplayName 'Jane' -UserPrincipalName 'jane@t.com' -WhatIf
            @($r.Steps)[0].Step | Should -Be 'Dry run'
            $r.UserId | Should -BeNullOrEmpty
            Should -Invoke New-EntraUser -Times 0
        }
    }

    Context 'Creation fails - workflow stops' {
        BeforeAll {
            Mock New-EntraUser { [PSCustomObject]@{ Status = '[!] User creation failed.'; Password = $null; UserId = $null } }
            Mock Set-EntraUserLicense { '[OK]' }
        }
        It 'Records the failure and runs no further steps' {
            $r = Invoke-EntraUserOnboarding -DisplayName 'Jane' -UserPrincipalName 'jane@t.com' -AddLicenseSkuId 'sku-1'
            $r.UserId | Should -BeNullOrEmpty
            @($r.Steps).Count | Should -Be 1
            Should -Invoke Set-EntraUserLicense -Times 0
        }
    }

    Context 'Full onboarding' {
        BeforeAll {
            Mock New-EntraUser { [PSCustomObject]@{ Status = '[OK] Created user jane@t.com'; Password = 'TempP@ss123'; UserId = 'new-oid' } }
            Mock Set-EntraUserLicense { '[OK] Updated licenses' }
            Mock Set-EntraGroupMembership { '[OK] Add membership' }
            Mock Set-EntraUserManager { '[OK] Set manager' }
            Mock Set-ExchangeMailboxPermission { '[OK] Mirrored permissions' }
        }
        It 'Applies license, group, manager and copy-access, returns password on the result only' {
            $r = Invoke-EntraUserOnboarding -DisplayName 'Jane' -UserPrincipalName 'jane@t.com' `
                    -AddLicenseSkuId 'sku-1' -AddToGroupId 'group-1' -ManagerId 'mgr-oid' -CopyAccessFromUpn 'peer@t.com'
            $r.UserId   | Should -Be 'new-oid'
            $r.Password | Should -Be 'TempP@ss123'
            Should -Invoke Set-EntraGroupMembership -Times 1 -Exactly -ParameterFilter { $UserId -eq 'new-oid' -and $Action -eq 'Add' }
            Should -Invoke Set-EntraUserManager     -Times 1 -Exactly
            Should -Invoke Set-ExchangeMailboxPermission -Times 1 -Exactly -ParameterFilter { $SourceUser -eq 'peer@t.com' -and $TargetUser -eq 'jane@t.com' }
            # Password must not appear in any step result
            ($r.Steps | Where-Object { $_.Result -like '*TempP@ss123*' }) | Should -BeNullOrEmpty
        }
    }
}
