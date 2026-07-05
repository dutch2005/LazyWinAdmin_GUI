Describe 'Invoke-LWAEntraPIMElevation' {
    BeforeAll {
        if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue)) { function Get-MgContext { } }
        if (-not (Get-Command Invoke-MgGraphRequest -ErrorAction SilentlyContinue)) { function Invoke-MgGraphRequest { } }
        . $PSScriptRoot\..\Private\Invoke-LWAEntraPIMElevation.ps1
    }

    Context 'When not connected to Graph' {
        It 'Returns an error object' {
            Mock Get-MgContext { return $null }
            $result = Invoke-LWAEntraPIMElevation -RoleTemplateId 'some-id' -Justification 'INC123 motivation'
            $result.Success | Should -Be $false
            $result.Error | Should -Match 'Not connected to Microsoft Graph'
        }
    }

    Context 'When connected to Graph' {
        It 'Successfully activates directory role' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'user@domain.com' } }
            
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{ id = 'user-object-id' }
            } -ParameterFilter { $Uri -match 'v1.0/me' }
            
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{ status = 'Granted' }
            } -ParameterFilter { $Uri -match 'roleAssignmentScheduleRequests' }

            $result = Invoke-LWAEntraPIMElevation -RoleTemplateId 'target-role-id' -Justification 'INC123 this is motivation'
            $result.Success | Should -Be $true
            $result.Status | Should -Be 'Granted'
        }

        It 'Successfully activates privileged group' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'user@domain.com' } }
            
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{ id = 'user-object-id' }
            } -ParameterFilter { $Uri -match 'v1.0/me' }
            
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{ status = 'Granted' }
            } -ParameterFilter { $Uri -match 'group/assignmentScheduleRequests' }

            $result = Invoke-LWAEntraPIMElevation -GroupId 'target-group-id' -Justification 'INC123 this is motivation'
            $result.Success | Should -Be $true
            $result.Status | Should -Be 'Granted'
        }

        It 'Fails validation if justification is too short or malformed' {
            { Invoke-LWAEntraPIMElevation -RoleTemplateId 'target-role-id' -Justification 'short' } | Should -Throw
            { Invoke-LWAEntraPIMElevation -RoleTemplateId 'target-role-id' -Justification 'NO-TICKET-FORMAT motivation' } | Should -Throw
        }

        It 'Handles Graph API errors gracefully' {
            Mock Get-MgContext { return [PSCustomObject]@{ Account = 'user@domain.com' } }
            
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{ id = 'user-object-id' }
            } -ParameterFilter { $Uri -match 'v1.0/me' }
            
            Mock Invoke-MgGraphRequest {
                throw 'Graph API Error: Denied'
            } -ParameterFilter { $Uri -match 'roleAssignmentScheduleRequests' }

            $result = Invoke-LWAEntraPIMElevation -RoleTemplateId 'target-role-id' -Justification 'INC123 Motivation text here'
            $result.Success | Should -Be $false
            $result.Error | Should -Match 'Graph API Error: Denied'
        }
    }
}
