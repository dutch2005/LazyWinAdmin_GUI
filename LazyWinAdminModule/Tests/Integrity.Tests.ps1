#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
<#
.SYNOPSIS
    Integrity tests for the LazyWinAdmin module.
    Verifies file structure, module manifest, XAML validity, and ApplicationState class.
    Pester v5 syntax only.
#>

BeforeAll {
    $script:ModuleRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'File Structure' {

    Context 'Private function files' {

        It 'Get-ComputerADInfo.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Get-ComputerADInfo.ps1' | Should -Exist
        }

        It 'Get-AzureResourceSummary.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Get-AzureResourceSummary.ps1' | Should -Exist
        }

        It 'Connect-ModernCloud.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Connect-ModernCloud.ps1' | Should -Exist
        }

        It 'Get-ComputerHardware.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Get-ComputerHardware.ps1' | Should -Exist
        }

        It 'Get-ComputerLocalGroup.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Get-ComputerLocalGroup.ps1' | Should -Exist
        }

        It 'Get-ComputerLocalUser.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Get-ComputerLocalUser.ps1' | Should -Exist
        }

        It 'Get-ComputerMotherboard.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Get-ComputerMotherboard.ps1' | Should -Exist
        }

        It 'Get-ComputerNetwork.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Get-ComputerNetwork.ps1' | Should -Exist
        }

        It 'Get-ComputerRegistryValue.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Get-ComputerRegistryValue.ps1' | Should -Exist
        }

        It 'Get-ComputerService.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Get-ComputerService.ps1' | Should -Exist
        }

        It 'Get-ComputerSoftware.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Get-ComputerSoftware.ps1' | Should -Exist
        }

        It 'Get-ComputerUptime.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Get-ComputerUptime.ps1' | Should -Exist
        }

        It 'Get-EntraIdentity.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Get-EntraIdentity.ps1' | Should -Exist
        }

        It 'Get-IntuneDevice.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Get-IntuneDevice.ps1' | Should -Exist
        }

        It 'Invoke-ComputerRegistry.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Invoke-ComputerRegistry.ps1' | Should -Exist
        }

        It 'Set-ComputerRDP.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Set-ComputerRDP.ps1' | Should -Exist
        }

        It 'Test-ComputerPort.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Test-ComputerPort.ps1' | Should -Exist
        }

        It 'Connect-ExchangeSession.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Connect-ExchangeSession.ps1' | Should -Exist
        }

        It 'Get-ExchangeMailboxPermission.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Get-ExchangeMailboxPermission.ps1' | Should -Exist
        }

        It 'Set-ExchangeMailboxPermission.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Set-ExchangeMailboxPermission.ps1' | Should -Exist
        }

        It 'Get-IntuneManagementScript.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Get-IntuneManagementScript.ps1' | Should -Exist
        }

        It 'Get-DeviceComplianceStatus.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Get-DeviceComplianceStatus.ps1' | Should -Exist
        }

        It 'Set-DeviceComplianceItem.ps1 exists' {
            Join-Path $script:ModuleRoot 'Private\Set-DeviceComplianceItem.ps1' | Should -Exist
        }
    }

    Context 'UI files' {
        It 'MainView.xaml exists' {
            Join-Path $script:ModuleRoot 'UI\MainView.xaml' | Should -Exist
        }
    }

    Context 'Classes files' {
        It 'ApplicationState.ps1 exists' {
            Join-Path $script:ModuleRoot 'Classes\ApplicationState.ps1' | Should -Exist
        }
    }

    Context 'Public files' {
        It 'Start-LazyWinAdmin.ps1 exists' {
            Join-Path $script:ModuleRoot 'Public\Start-LazyWinAdmin.ps1' | Should -Exist
        }
    }

    Context 'Module manifest' {
        It 'LazyWinAdminModule.psd1 exists' {
            Join-Path $script:ModuleRoot 'LazyWinAdminModule.psd1' | Should -Exist
        }
    }

    Context 'Root module' {
        It 'LazyWinAdminModule.psm1 exists' {
            Join-Path $script:ModuleRoot 'LazyWinAdminModule.psm1' | Should -Exist
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'Module Manifest' {

    BeforeAll {
        $script:ManifestPath = Join-Path $script:ModuleRoot 'LazyWinAdminModule.psd1'
        # Import-PowerShellDataFile parses the .psd1 as data only — no code execution
        $script:Manifest     = Import-PowerShellDataFile -Path $script:ManifestPath
    }

    It 'Manifest parses without error' {
        $script:Manifest | Should -Not -BeNullOrEmpty
    }

    It 'PowerShellVersion is 7.4' {
        $script:Manifest.PowerShellVersion | Should -Be '7.4'
    }

    It 'FunctionsToExport contains Start-LazyWinAdmin' {
        $script:Manifest.FunctionsToExport | Should -Contain 'Start-LazyWinAdmin'
    }

    It 'RequiredModules does NOT contain ThreadJob' {
        # RequiredModules may be strings or hashtables with ModuleName key
        $names = $script:Manifest.RequiredModules | ForEach-Object {
            if ($_ -is [string])    { $_ }
            elseif ($_ -is [hashtable]) { $_.ModuleName }
        }
        $names | Should -Not -Contain 'ThreadJob'
    }

    It 'ModuleVersion is set and non-empty' {
        $script:Manifest.ModuleVersion | Should -Not -BeNullOrEmpty
    }

    It 'RootModule references a .psm1 file' {
        $script:Manifest.RootModule | Should -Match '\.psm1$'
    }

    It 'GUID is set and non-empty' {
        $script:Manifest.GUID | Should -Not -BeNullOrEmpty
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'XAML Validity' {

    BeforeAll {
        $script:XamlPath    = Join-Path $script:ModuleRoot 'UI\MainView.xaml'
        $script:XamlContent = Get-Content -Path $script:XamlPath -Raw -ErrorAction Stop
        $script:XmlDoc      = [System.Xml.XmlDocument]::new()
        $script:XmlDoc.LoadXml($script:XamlContent)
    }

    It 'XAML file content is not empty' {
        $script:XamlContent | Should -Not -BeNullOrEmpty
    }

    It 'XAML loads into XmlDocument without throwing' {
        { [System.Xml.XmlDocument]::new().LoadXml($script:XamlContent) } | Should -Not -Throw
    }

    It 'XAML root element is Window' {
        $script:XmlDoc.DocumentElement.LocalName | Should -Be 'Window'
    }

    # Each x:Name or Name control expected in the UI.
    # Using -TestCases instead of foreach+It because in Pester v5, It blocks collected during
    # discovery run AFTER the foreach loop finishes — the loop variable goes out of scope.
    # -TestCases binds each value at discovery time so it is available when the test runs.
    It "XAML contains named control '<ControlName>'" -TestCases @(
        @{ ControlName = 'txtComputerName'   }
        @{ ControlName = 'btnPing'           }
        @{ ControlName = 'btnUptime'         }
        @{ ControlName = 'btnEnableRdp'      }
        @{ ControlName = 'btnDisableRdp'     }
        @{ ControlName = 'txtOutput'         }
        @{ ControlName = 'btnGetServices'    }
        @{ ControlName = 'btnGetSoftware'    }
        @{ ControlName = 'btnGetHardware'    }
        @{ ControlName = 'btnGetNetwork'     }
        @{ ControlName = 'btnGetLocalUsers'  }
        @{ ControlName = 'btnGetLocalGroups' }
        @{ ControlName = 'btnGetEntraUsers'  }
        @{ ControlName = 'btnGetEntraGroups' }
        @{ ControlName = 'btnGetIntuneDevices' }
        @{ ControlName = 'btnGetAzureSummary' }
        @{ ControlName = 'btnRegRead'        }
        @{ ControlName = 'btnRegWrite'       }
        @{ ControlName = 'btnRegDelete'      }
        @{ ControlName = 'cbRegHive'         }
        @{ ControlName = 'btnCloudLogin'     }
        @{ ControlName = 'lblCloudStatus'    }
        @{ ControlName = 'lblStatus'         }
        @{ ControlName = 'lblAdminStatus'    }
        @{ ControlName = 'btnRestartAdmin'           }
        @{ ControlName = 'btnGetIntuneScripts'       }
        @{ ControlName = 'txtIntuneScriptSearch'     }
        @{ ControlName = 'txtIntuneScriptDownloadPath' }
        @{ ControlName = 'btnDownloadIntuneScripts'  }
        @{ ControlName = 'lvIntuneScripts'           }
        @{ ControlName = 'btnCheckCompliance'        }
        @{ ControlName = 'lvComplianceStatus'        }
        @{ ControlName = 'btnFixLocation'            }
        @{ ControlName = 'btnFixOutlookImages'       }
        @{ ControlName = 'btnRemoveOneDrive'         }
        @{ ControlName = 'txtUpdateHoursStart'       }
        @{ ControlName = 'txtUpdateHoursEnd'         }
        @{ ControlName = 'btnFixUpdateHours'         }
        @{ ControlName = 'txtComplianceOutput'       }
        @{ ControlName = 'txtExchangeUpn'            }
        @{ ControlName = 'btnConnectExchange'        }
        @{ ControlName = 'lblExchangeStatus'         }
        @{ ControlName = 'btnGetMailboxPerms'        }
        @{ ControlName = 'txtExchangeViewUser'       }
        @{ ControlName = 'lvMailboxPerms'            }
        @{ ControlName = 'txtExchangeSourceUser'     }
        @{ ControlName = 'txtExchangeTargetUser'     }
        @{ ControlName = 'btnMirrorMailboxPerms'     }
        @{ ControlName = 'txtExchangeMailbox'        }
        @{ ControlName = 'txtExchangeGrantUser'      }
        @{ ControlName = 'btnGrantMailboxPerms'      }
    ) {
        param($ControlName)
        # XPath that finds any element whose local-name attribute (x:Name or Name) equals the control name
        $xpath = "//*[@*[local-name()='Name' and . = '$ControlName']]"
        $nodes = $script:XmlDoc.SelectNodes($xpath)
        ($nodes | Measure-Object).Count | Should -BeGreaterThan 0
    }
}

# ─────────────────────────────────────────────────────────────────────────────
Describe 'ApplicationState Class' {

    BeforeAll {
        . (Join-Path $script:ModuleRoot 'Classes\ApplicationState.ps1')
        $script:State = [LazyWinAdminState]::new()
    }

    AfterAll {
        if ($script:State) {
            try { $script:State.Dispose() } catch { Write-Verbose "Dispose error during test teardown: $_" }
        }
    }

    It 'Instantiates without throwing' {
        $script:State | Should -Not -BeNullOrEmpty
    }

    It 'SyncHash is not null' {
        $script:State.SyncHash | Should -Not -BeNullOrEmpty
    }

    It 'SyncHash is a synchronized hashtable' {
        $script:State.SyncHash | Should -BeOfType [hashtable]
        # The synchronized wrapper type name contains 'SyncHash' on .NET
        $script:State.SyncHash.GetType().FullName | Should -Match 'SyncHash|Synchronized'
    }

    It 'SyncHash.IsBusy defaults to $false' {
        $script:State.SyncHash.IsBusy | Should -BeFalse
    }

    It 'SyncHash.CloudConnected defaults to $false' {
        $script:State.SyncHash.CloudConnected | Should -BeFalse
    }

    It 'SyncHash.ExchangeConnected defaults to $false' {
        $script:State.SyncHash.ExchangeConnected | Should -BeFalse
    }

    It 'SyncHash.UIQueue is a ConcurrentQueue' {
        # An empty ConcurrentQueue evaluates as empty when piped — assert on the type directly.
        ($null -ne $script:State.SyncHash.UIQueue) | Should -BeTrue
        $script:State.SyncHash.UIQueue.GetType().Name | Should -BeLike 'ConcurrentQueue*'
    }

    It 'SyncHash.Logs is an ArrayList' {
        # Piping an empty collection to Should iterates it (yielding nothing).
        # Assert on the type name directly to avoid that problem.
        $script:State.SyncHash.Logs.GetType().FullName | Should -Be 'System.Collections.ArrayList'
    }

    It 'RunspacePool is not null' {
        $script:State.RunspacePool | Should -Not -BeNullOrEmpty
    }

    It 'RunspacePool is in Opened state' {
        $script:State.RunspacePool.RunspacePoolStateInfo.State | Should -Be 'Opened'
    }

    It 'CimSessions is not null' {
        # CimSessions starts as an empty synchronized hashtable — it IS empty but NOT null.
        # Wrap in a boolean expression: piping an empty hashtable through the pipeline yields
        # zero items, which Pester treats as $null/empty even for -Not -BeNull.
        ($null -ne $script:State.CimSessions) | Should -BeTrue
    }

    It 'CimSessions is a synchronized hashtable' {
        $script:State.CimSessions | Should -BeOfType [hashtable]
        $script:State.CimSessions.GetType().FullName | Should -Match 'SyncHash|Synchronized'
    }

    It 'Log method appends a new entry to SyncHash.Logs' {
        $countBefore = $script:State.SyncHash.Logs.Count
        $script:State.Log('Integrity test log entry')
        $script:State.SyncHash.Logs.Count | Should -BeGreaterThan $countBefore
    }

    It 'Log method formats entry with [yyyy-MM-dd HH:mm:ss] timestamp prefix' {
        $script:State.Log('Timestamp format check')
        $lastEntry = $script:State.SyncHash.Logs[$script:State.SyncHash.Logs.Count - 1]
        $lastEntry | Should -Match '^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] '
    }

    It 'Log method includes the message text in the entry' {
        $uniqueMsg = "PESTER-UNIQUE-$(Get-Random)"
        $script:State.Log($uniqueMsg)
        $lastEntry = $script:State.SyncHash.Logs[$script:State.SyncHash.Logs.Count - 1]
        # Assign escaped pattern to a variable first — passing [regex]::Escape() inline
        # to Should -Match causes Pester to receive the literal string '[regex]::Escape'
        # rather than the evaluated result in some versions.
        $pattern = [regex]::Escape($uniqueMsg)
        $lastEntry | Should -Match $pattern
    }

    It 'EvictCimSession removes a cached entry' {
        $fakeKey = 'FAKE-HOST-EVICT-TEST'
        # Inject a null placeholder — the cache key existence is what we test
        $script:State.CimSessions[$fakeKey] = $null
        $script:State.CimSessions.ContainsKey($fakeKey) | Should -BeTrue

        # EvictCimSession calls Remove-CimSession with SilentlyContinue so null value is fine
        $script:State.EvictCimSession($fakeKey)
        $script:State.CimSessions.ContainsKey($fakeKey) | Should -BeFalse
    }

    It 'EvictCimSession is a no-op for a non-existent key' {
        { $script:State.EvictCimSession('HOST-DOES-NOT-EXIST') } | Should -Not -Throw
    }

    It 'Dispose does not throw' {
        $disposable = [LazyWinAdminState]::new()
        { $disposable.Dispose() } | Should -Not -Throw
    }

    It 'Dispose closes the RunspacePool' {
        $disposable = [LazyWinAdminState]::new()
        $disposable.Dispose()
        $disposable.RunspacePool.RunspacePoolStateInfo.State | Should -Be 'Closed'
    }

    It 'Dispose clears the CimSessions cache' {
        $disposable = [LazyWinAdminState]::new()
        $disposable.CimSessions['SOME-HOST'] = $null
        $disposable.Dispose()
        $disposable.CimSessions.Count | Should -Be 0
    }
}
