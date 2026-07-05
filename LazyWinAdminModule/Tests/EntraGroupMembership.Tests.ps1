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
    if (-not (Get-Command Get-MgUserMemberOf -ErrorAction SilentlyContinue)) {
        function Get-MgUserMemberOf { param([string]$UserId, [switch]$All) }
    }
    if (-not (Get-Command Get-MgGroupMember -ErrorAction SilentlyContinue)) {
        function Get-MgGroupMember { param([string]$GroupId, [switch]$All) }
    }
    if (-not (Get-Command New-MgGroupMember -ErrorAction SilentlyContinue)) {
        function New-MgGroupMember { param([string]$GroupId, [string]$DirectoryObjectId) }
    }
    if (-not (Get-Command Remove-MgGroupMemberByRef -ErrorAction SilentlyContinue)) {
        function Remove-MgGroupMemberByRef { param([string]$GroupId, [string]$DirectoryObjectId) }
    }
}

Describe 'Get-EntraUserMembership' {

    Context 'Guard - not connected' {
        BeforeAll { Mock Get-MgContext { $null } }
        It 'Returns $null when not connected' {
            (Get-EntraUserMembership -UserPrincipalName 'u@t.com') | Should -BeNullOrEmpty
        }
    }

    Context 'Success' {
        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } }
            Mock Get-MgUserMemberOf {
                [PSCustomObject]@{
                    Id                   = 'group-1'
                    AdditionalProperties = @{ 'displayName' = 'Sales'; '@odata.type' = '#microsoft.graph.group' }
                }
            }
        }
        It 'Projects DisplayName and strips the odata type prefix' {
            $m = Get-EntraUserMembership -UserPrincipalName 'u@t.com'
            $m.DisplayName | Should -Be 'Sales'
            $m.Type        | Should -Be 'group'
            $m.Id          | Should -Be 'group-1'
        }
    }
}

Describe 'Get-EntraGroupMember' {

    Context 'Guard - not connected' {
        BeforeAll { Mock Get-MgContext { $null } }
        It 'Returns $null when not connected' {
            (Get-EntraGroupMember -GroupId 'group-1') | Should -BeNullOrEmpty
        }
    }

    Context 'Success' {
        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } }
            Mock Get-MgGroupMember {
                [PSCustomObject]@{
                    Id                   = 'user-1'
                    AdditionalProperties = @{ 'displayName' = 'Jane Doe'; 'userPrincipalName' = 'jane@t.com' }
                }
            }
        }
        It 'Projects member DisplayName and UPN' {
            $m = Get-EntraGroupMember -GroupId 'group-1'
            $m.DisplayName       | Should -Be 'Jane Doe'
            $m.UserPrincipalName | Should -Be 'jane@t.com'
        }
    }
}

Describe 'Set-EntraGroupMembership' {

    Context 'Guard - not connected' {
        BeforeAll { Mock Get-MgContext { $null } }
        It 'Returns [!] without calling New-MgGroupMember' {
            Mock New-MgGroupMember { }
            $r = Set-EntraGroupMembership -GroupId 'g' -UserId 'u' -Action 'Add'
            $r | Should -Match '^\[!\]'
            Should -Invoke New-MgGroupMember -Times 0
        }
    }

    Context 'WhatIf' {
        BeforeAll { Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } } }
        It 'Skips under -WhatIf' {
            Mock New-MgGroupMember { }
            Set-EntraGroupMembership -GroupId 'g' -UserId 'u' -Action 'Add' -WhatIf | Should -BeLike '*Skipped by -WhatIf*'
            Should -Invoke New-MgGroupMember -Times 0
        }
    }

    Context 'Add' {
        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } }
            Mock New-MgGroupMember { }
        }
        It 'Invokes New-MgGroupMember with the group and user ids' {
            $r = Set-EntraGroupMembership -GroupId 'group-1' -UserId 'user-1' -Action 'Add'
            $r | Should -Match '^\[OK\]'
            Should -Invoke New-MgGroupMember -Times 1 -Exactly -ParameterFilter {
                $GroupId -eq 'group-1' -and $DirectoryObjectId -eq 'user-1'
            }
        }
    }

    Context 'Remove' {
        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } }
            Mock Remove-MgGroupMemberByRef { }
        }
        It 'Invokes Remove-MgGroupMemberByRef' {
            $r = Set-EntraGroupMembership -GroupId 'group-1' -UserId 'user-1' -Action 'Remove'
            $r | Should -Match '^\[OK\]'
            Should -Invoke Remove-MgGroupMemberByRef -Times 1 -Exactly -ParameterFilter {
                $GroupId -eq 'group-1' -and $DirectoryObjectId -eq 'user-1'
            }
        }
    }

    Context 'Failure' {
        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } }
            Mock New-MgGroupMember { throw 'Insufficient privileges' }
        }
        It 'Returns sanitised [!]' {
            $r = Set-EntraGroupMembership -GroupId 'g' -UserId 'u' -Action 'Add'
            $r | Should -Match '^\[!\]'
            $r | Should -Not -Match 'Insufficient privileges'
        }
    }
}
