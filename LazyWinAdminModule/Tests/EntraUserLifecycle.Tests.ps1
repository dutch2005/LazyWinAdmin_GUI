#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Mock stub functions declare params to match real cmdlet signatures.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseShouldProcessForStateChangingFunctions', '',
    Justification = 'Stub functions emulate real Graph cmdlet names for mocking; they perform no work.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingUsernameAndPasswordParams', '',
    Justification = 'Update-MgUser stub mirrors the real cmdlet signature for mocking; no credential is handled.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingPlainTextForPassword', '',
    Justification = 'Update-MgUser stub mirrors the real cmdlet signature for mocking; no password is stored or transmitted.')]
param()

BeforeAll {
    $script:ModuleRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    Get-ChildItem (Join-Path $script:ModuleRoot 'Classes') -Filter '*.ps1' | ForEach-Object { . $_.FullName }
    Get-ChildItem (Join-Path $script:ModuleRoot 'Private') -Filter '*.ps1' | ForEach-Object { . $_.FullName }
    Get-ChildItem (Join-Path $script:ModuleRoot 'Public')  -Filter '*.ps1' | ForEach-Object { . $_.FullName }

    # Graph cmdlet stubs — only defined when the real command is absent, so Mock can attach.
    if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue)) {
        function Get-MgContext { }
    }
    if (-not (Get-Command Update-MgUser -ErrorAction SilentlyContinue)) {
        function Update-MgUser { param([string]$UserId, $PasswordProfile, [bool]$AccountEnabled) }
    }
    if (-not (Get-Command Revoke-MgUserSignInSession -ErrorAction SilentlyContinue)) {
        function Revoke-MgUserSignInSession { param([string]$UserId) }
    }
    if (-not (Get-Command Get-MgSubscribedSku -ErrorAction SilentlyContinue)) {
        function Get-MgSubscribedSku { }
    }
    if (-not (Get-Command Get-MgUserLicenseDetail -ErrorAction SilentlyContinue)) {
        function Get-MgUserLicenseDetail { param([string]$UserId) }
    }
    if (-not (Get-Command Set-MgUserLicense -ErrorAction SilentlyContinue)) {
        function Set-MgUserLicense { param([string]$UserId, $AddLicenses, $RemoveLicenses) }
    }
}

Describe 'New-LwaSecurePassword' {

    It 'Returns a string of the requested length' {
        (New-LwaSecurePassword -Length 20).Length | Should -Be 20
    }

    It 'Defaults to length 16' {
        (New-LwaSecurePassword).Length | Should -Be 16
    }

    It 'Contains at least one upper, lower, digit and symbol' {
        $pw = New-LwaSecurePassword
        $pw | Should -Match '[A-Z]'
        $pw | Should -Match '[a-z]'
        $pw | Should -Match '[0-9]'
        $pw | Should -Match '[!@#$%^&*\-_=+?]'
    }

    It 'Produces a different value on each call' {
        (New-LwaSecurePassword) | Should -Not -Be (New-LwaSecurePassword)
    }

    It 'Rejects a length below the minimum' {
        { New-LwaSecurePassword -Length 4 } | Should -Throw
    }
}

Describe 'Set-EntraUserPassword' {

    Context 'Guard - not connected to Graph' {
        BeforeAll { Mock Get-MgContext { $null } }

        It 'Returns [!] status and null password without calling Update-MgUser' {
            Mock Update-MgUser { }
            $result = Set-EntraUserPassword -UserPrincipalName 'u@t.com'
            $result.Status   | Should -Match '^\[!\]'
            $result.Password | Should -BeNullOrEmpty
            Should -Invoke Update-MgUser -Times 0
        }
    }

    Context 'WhatIf' {
        BeforeAll { Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } } }

        It 'Skips and returns null password under -WhatIf' {
            Mock Update-MgUser { }
            $result = Set-EntraUserPassword -UserPrincipalName 'u@t.com' -WhatIf
            $result.Status   | Should -BeLike '*Skipped by -WhatIf*'
            $result.Password | Should -BeNullOrEmpty
            Should -Invoke Update-MgUser -Times 0
        }
    }

    Context 'Success' {
        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } }
            Mock Update-MgUser { }
        }

        It 'Returns [OK] status and a non-empty password' {
            $result = Set-EntraUserPassword -UserPrincipalName 'u@t.com'
            $result.Status   | Should -Match '^\[OK\]'
            $result.Password | Should -Not -BeNullOrEmpty
        }

        It 'Forces password change at next sign-in by default' {
            Set-EntraUserPassword -UserPrincipalName 'u@t.com' | Out-Null
            Should -Invoke Update-MgUser -Times 1 -Exactly -ParameterFilter {
                $PasswordProfile.ForceChangePasswordNextSignIn -eq $true -and
                -not [string]::IsNullOrEmpty($PasswordProfile.Password)
            }
        }

        It 'Never places the password in the Status string (no leak into logs)' {
            $result = Set-EntraUserPassword -UserPrincipalName 'u@t.com'
            $result.Status | Should -Not -BeLike "*$($result.Password)*"
        }
    }

    Context 'Failure' {
        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } }
            Mock Update-MgUser { throw 'Insufficient privileges to complete the operation' }
        }

        It 'Returns sanitised [!] status without exception detail' {
            $result = Set-EntraUserPassword -UserPrincipalName 'u@t.com'
            $result.Status   | Should -Match '^\[!\]'
            $result.Status   | Should -Not -Match 'Insufficient privileges'
            $result.Password | Should -BeNullOrEmpty
        }
    }
}

Describe 'Revoke-EntraUserSession' {

    Context 'Guard - not connected' {
        BeforeAll { Mock Get-MgContext { $null } }
        It 'Returns [!] without calling Revoke-MgUserSignInSession' {
            Mock Revoke-MgUserSignInSession { }
            $r = Revoke-EntraUserSession -UserPrincipalName 'u@t.com'
            $r | Should -Match '^\[!\]'
            Should -Invoke Revoke-MgUserSignInSession -Times 0
        }
    }

    Context 'Success' {
        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } }
            Mock Revoke-MgUserSignInSession { }
        }
        It 'Returns [OK] and invokes the revoke cmdlet' {
            $r = Revoke-EntraUserSession -UserPrincipalName 'u@t.com'
            $r | Should -Match '^\[OK\]'
            Should -Invoke Revoke-MgUserSignInSession -Times 1 -Exactly -ParameterFilter { $UserId -eq 'u@t.com' }
        }
    }

    Context 'Failure' {
        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } }
            Mock Revoke-MgUserSignInSession { throw 'Graph error' }
        }
        It 'Returns sanitised [!]' {
            $r = Revoke-EntraUserSession -UserPrincipalName 'u@t.com'
            $r | Should -Match '^\[!\]'
            $r | Should -Not -Match 'Graph error'
        }
    }
}

Describe 'Get-EntraLicenseSku' {

    Context 'Guard - not connected' {
        BeforeAll { Mock Get-MgContext { $null } }
        It 'Returns $null when not connected' {
            (Get-EntraLicenseSku) | Should -BeNullOrEmpty
        }
    }

    Context 'Success' {
        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } }
            Mock Get-MgSubscribedSku {
                [PSCustomObject]@{
                    SkuPartNumber = 'ENTERPRISEPACK'
                    SkuId         = '00000000-0000-0000-0000-000000000001'
                    ConsumedUnits = 8
                    PrepaidUnits  = [PSCustomObject]@{ Enabled = 10 }
                }
            }
        }
        It 'Computes Available = Enabled - Consumed' {
            $sku = Get-EntraLicenseSku
            $sku.SkuPartNumber | Should -Be 'ENTERPRISEPACK'
            $sku.Available     | Should -Be 2
        }
    }

    Context 'Failure' {
        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } }
            Mock Get-MgSubscribedSku { throw 'Graph error' }
        }
        It 'Returns $null on error' {
            (Get-EntraLicenseSku) | Should -BeNullOrEmpty
        }
    }
}

Describe 'Get-EntraUserLicense' {

    Context 'Guard - not connected' {
        BeforeAll { Mock Get-MgContext { $null } }
        It 'Returns $null when not connected' {
            (Get-EntraUserLicense -UserPrincipalName 'u@t.com') | Should -BeNullOrEmpty
        }
    }

    Context 'Success' {
        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } }
            Mock Get-MgUserLicenseDetail {
                [PSCustomObject]@{ SkuPartNumber = 'ENTERPRISEPACK'; SkuId = 'sku-1' }
            }
        }
        It 'Returns the user license SKUs' {
            $lic = Get-EntraUserLicense -UserPrincipalName 'u@t.com'
            $lic.SkuPartNumber | Should -Be 'ENTERPRISEPACK'
        }
    }
}

Describe 'Set-EntraUserLicense' {

    Context 'Guard - not connected' {
        BeforeAll { Mock Get-MgContext { $null } }
        It 'Returns [!] without calling Set-MgUserLicense' {
            Mock Set-MgUserLicense { }
            $r = Set-EntraUserLicense -UserPrincipalName 'u@t.com' -AddSkuId 'sku-1'
            $r | Should -Match '^\[!\]'
            Should -Invoke Set-MgUserLicense -Times 0
        }
    }

    Context 'No SKU specified' {
        BeforeAll { Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } } }
        It 'Returns [!] when neither add nor remove is given' {
            Set-EntraUserLicense -UserPrincipalName 'u@t.com' | Should -BeLike '*Specify a SKU*'
        }
    }

    Context 'WhatIf' {
        BeforeAll { Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } } }
        It 'Skips under -WhatIf' {
            Mock Set-MgUserLicense { }
            Set-EntraUserLicense -UserPrincipalName 'u@t.com' -AddSkuId 'sku-1' -WhatIf | Should -BeLike '*Skipped by -WhatIf*'
            Should -Invoke Set-MgUserLicense -Times 0
        }
    }

    Context 'Add and remove' {
        BeforeAll {
            Mock Get-MgContext { [PSCustomObject]@{ TenantId = 't' } }
            Mock Set-MgUserLicense { }
        }
        It 'Assigns the add SKU and leaves removes empty when only adding' {
            Set-EntraUserLicense -UserPrincipalName 'u@t.com' -AddSkuId 'sku-add' | Out-Null
            Should -Invoke Set-MgUserLicense -Times 1 -Exactly -ParameterFilter {
                $AddLicenses[0].SkuId -eq 'sku-add' -and @($RemoveLicenses).Count -eq 0
            }
        }
        It 'Passes the remove SKU id when only removing' {
            Set-EntraUserLicense -UserPrincipalName 'u@t.com' -RemoveSkuId 'sku-rem' | Out-Null
            Should -Invoke Set-MgUserLicense -Times 1 -Exactly -ParameterFilter {
                $RemoveLicenses[0] -eq 'sku-rem' -and @($AddLicenses).Count -eq 0
            }
        }
        It 'Returns [OK] on success' {
            Set-EntraUserLicense -UserPrincipalName 'u@t.com' -AddSkuId 'sku-add' | Should -Match '^\[OK\]'
        }
    }
}
