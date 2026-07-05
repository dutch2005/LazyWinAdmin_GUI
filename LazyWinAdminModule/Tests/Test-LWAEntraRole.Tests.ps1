Describe 'Test-LWAEntraRole' {
    BeforeAll {
        if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue)) { function Get-MgContext { } }
        if (-not (Get-Command Invoke-MgGraphRequest -ErrorAction SilentlyContinue)) { function Invoke-MgGraphRequest { } }
        . $PSScriptRoot\..\Private\Test-LWAEntraRole.ps1
    }

    Context 'When not connected to Graph' {
        It 'Returns false' {
            Mock Get-MgContext { return $null }
            $result = Test-LWAEntraRole -RoleTemplateId 'some-id'
            $result | Should -Be $false
        }
    }

    Context 'When connected to Graph' {
        It 'Returns true if user has the specific role' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'user@domain.com' } }
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{
                    value = @(
                        [PSCustomObject]@{ roleTemplateId = 'target-role-id' }
                    )
                }
            } -ParameterFilter { $Uri -match 'me/memberOf/microsoft.graph.directoryRole' }

            $result = Test-LWAEntraRole -RoleTemplateId 'target-role-id'
            $result | Should -Be $true
        }

        It 'Returns true if user has Global Admin role' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'user@domain.com' } }
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{
                    value = @(
                        [PSCustomObject]@{ roleTemplateId = '62e90394-69f5-4237-9190-012177145e10' }
                    )
                }
            } -ParameterFilter { $Uri -match 'me/memberOf/microsoft.graph.directoryRole' }

            $result = Test-LWAEntraRole -RoleTemplateId 'target-role-id'
            $result | Should -Be $true
        }

        It 'Returns false if user lacks the role' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'user@domain.com' } }
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{
                    value = @(
                        [PSCustomObject]@{ roleTemplateId = 'other-role-id' }
                    )
                }
            } -ParameterFilter { $Uri -match 'me/memberOf/microsoft.graph.directoryRole' }

            $result = Test-LWAEntraRole -RoleTemplateId 'target-role-id'
            $result | Should -Be $false
        }
        
        It 'Returns false if API fails' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'user@domain.com' } }
            Mock Invoke-MgGraphRequest { throw 'API Error' }
            
            $result = Test-LWAEntraRole -RoleTemplateId 'target-role-id'
            $result | Should -Be $false
        }
        It 'Returns true if user is member of the specific group' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'user@domain.com' } }
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{
                    value = @(
                        [PSCustomObject]@{ id = 'target-group-id' }
                    )
                }
            } -ParameterFilter { $Uri -match 'me/memberOf/microsoft.graph.group' }

            $result = Test-LWAEntraRole -GroupId 'target-group-id'
            $result | Should -Be $true
        }

        It 'Returns false if user is not member of the group' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'user@domain.com' } }
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{
                    value = @(
                        [PSCustomObject]@{ id = 'other-group-id' }
                    )
                }
            } -ParameterFilter { $Uri -match 'me/memberOf/microsoft.graph.group' }

            $result = Test-LWAEntraRole -GroupId 'target-group-id'
            $result | Should -Be $false
        }
    }
}
