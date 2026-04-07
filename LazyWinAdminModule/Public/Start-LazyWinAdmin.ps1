function Start-LazyWinAdmin {
    <#
    .SYNOPSIS
        Starts the modernized WPF-based LazyWinAdmin GUI.
    #>
    [CmdletBinding()]
    param ()

    # Load required assemblies for WPF
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    # Initialize State
    $state = [LazyWinAdminState]::new()

    # Canonical path for all Private function files.
    # Used to build InitializationScript values — never use Get-Content + Invoke-Expression.
    $PrivatePath = (Resolve-Path (Join-Path $PSScriptRoot "..\Private")).Path

    try {
        $xamlPath    = Join-Path $PSScriptRoot "..\UI\MainView.xaml"
        $xamlContent = Get-Content -Path $xamlPath -Raw

        $xmlDoc    = [System.Xml.XmlDocument]::new()
        $xmlDoc.LoadXml($xamlContent)
        $xmlReader = [System.Xml.XmlNodeReader]::new($xmlDoc)
        $window    = [System.Windows.Markup.XamlReader]::Load($xmlReader)

        # --- FIND CONTROLS ---
        $txtComputerName   = $window.FindName("txtComputerName")
        $btnPing           = $window.FindName("btnPing")
        $btnUptime         = $window.FindName("btnUptime")
        $btnEnableRdp      = $window.FindName("btnEnableRdp")
        $btnDisableRdp     = $window.FindName("btnDisableRdp")
        $txtOutput         = $window.FindName("txtOutput")

        $btnGetServices    = $window.FindName("btnGetServices")
        $btnGetStoppedAuto = $window.FindName("btnGetStoppedAuto")
        $lvServices        = $window.FindName("lvServices")
        $txtServiceSearch  = $window.FindName("txtServiceSearch")

        $btnGetSoftware    = $window.FindName("btnGetSoftware")
        $lvSoftware        = $window.FindName("lvSoftware")
        $txtSoftwareSearch = $window.FindName("txtSoftwareSearch")

        $btnGetHardware    = $window.FindName("btnGetHardware")
        $txtHwModel        = $window.FindName("txtHwModel")
        $txtHwSerial       = $window.FindName("txtHwSerial")
        $txtHwCpu          = $window.FindName("txtHwCpu")
        $txtHwRam          = $window.FindName("txtHwRam")
        $txtHwOs           = $window.FindName("txtHwOs")
        $txtHwMobo         = $window.FindName("txtHwMobo")
        $lvHwDisks         = $window.FindName("lvHwDisks")

        $btnGetNetwork     = $window.FindName("btnGetNetwork")
        $chkOnlyIPEnabled  = $window.FindName("chkOnlyIPEnabled")
        $lvNetwork         = $window.FindName("lvNetwork")

        $btnGetLocalUsers  = $window.FindName("btnGetLocalUsers")
        $btnGetLocalGroups = $window.FindName("btnGetLocalGroups")
        $lvLocalAccounts   = $window.FindName("lvLocalAccounts")
        $btnGetEntraUsers  = $window.FindName("btnGetEntraUsers")
        $btnGetEntraGroups = $window.FindName("btnGetEntraGroups")
        $lvEntraIdentity   = $window.FindName("lvEntraIdentity")
        $txtEntraSearch    = $window.FindName("txtEntraSearch")

        $btnGetIntuneDevices = $window.FindName("btnGetIntuneDevices")
        $lvIntuneDevices     = $window.FindName("lvIntuneDevices")
        $txtIntuneSearch     = $window.FindName("txtIntuneSearch")
        $btnGetAzureSummary  = $window.FindName("btnGetAzureSummary")
        $lvAzureResources    = $window.FindName("lvAzureResources")

        $btnRegRead        = $window.FindName("btnRegRead")
        $btnRegWrite       = $window.FindName("btnRegWrite")
        $btnRegDelete      = $window.FindName("btnRegDelete")
        $cbRegHive         = $window.FindName("cbRegHive")
        $cbRegType         = $window.FindName("cbRegType")
        $txtRegValueName   = $window.FindName("txtRegValueName")
        $txtRegValueData   = $window.FindName("txtRegValueData")
        $txtRegPath        = $window.FindName("txtRegPath")
        $txtRegResult      = $window.FindName("txtRegResult")

        $btnGetAdComputer  = $window.FindName("btnGetAdComputer")
        $btnGetAdUsers     = $window.FindName("btnGetAdUsers")
        $btnGetAdGroups    = $window.FindName("btnGetAdGroups")
        $txtAdSearch       = $window.FindName("txtAdSearch")
        $lvAdResults       = $window.FindName("lvAdResults")

        $btnCloudLogin     = $window.FindName("btnCloudLogin")
        $lblCloudStatus    = $window.FindName("lblCloudStatus")
        $txtTenantId       = $window.FindName("txtTenantId")
        $txtClientId       = $window.FindName("txtClientId")
        $txtClientSecret   = $window.FindName("txtClientSecret")
        $btnCloudConnectSP = $window.FindName("btnCloudConnectSP")

        $lblStatus         = $window.FindName("lblStatus")
        $pbBusy            = $window.FindName("pbBusy")

        # Default Value
        $txtComputerName.Text = $env:COMPUTERNAME

        # --- UI HELPERS ---
        $AppendOutput = {
            param($text)
            $window.Dispatcher.Invoke([action]{
                $txtOutput.AppendText("$text`n")
                $txtOutput.ScrollToEnd()
            })
        }

        $SetBusy = {
            param([bool]$isBusy)
            $window.Dispatcher.Invoke([action]{
                $pbBusy.IsIndeterminate = $isBusy
                $lblStatus.Text = if ($isBusy) { "Working..." } else { "Ready" }
            })
        }

        # --- PRE-FLIGHT GUARDS ---
        # These run synchronously on the UI thread before any async dispatch.
        # Return $false to abort the action; the handler should 'return' immediately.

        # Checks that the user has successfully authenticated against Entra ID / Azure.
        # Must be called before any button handler that invokes a CLOUD-layer function.
        $RequireCloudSession = {
            if (-not $state.SyncHash.CloudConnected) {
                $lblStatus.Text = "[!] Cloud authentication required — connect on the Cloud tab first."
                $AppendOutput.Invoke("[!] Action blocked: not authenticated. Use the Cloud tab to connect to Entra ID / Azure first.")
                return $false
            }
            return $true
        }

        # Checks that a non-empty computer name has been entered.
        # Must be called before any button handler that opens a CIM session.
        $RequireComputerName = {
            if ([string]::IsNullOrWhiteSpace($txtComputerName.Text)) {
                $lblStatus.Text = "[!] No computer name — enter a target in the Computer Name field."
                $AppendOutput.Invoke("[!] Action blocked: enter a Computer Name before running this action.")
                return $false
            }
            return $true
        }

        # --- ASYNC HELPER ---
        # Critical changes from previous version:
        #
        #   1. REMOVED: Get-Content + Invoke-Expression pattern.
        #      Private functions are now loaded into the thread job runspace via -InitializationScript,
        #      which dot-sources the file at the known path. The file path is embedded at call-site
        #      construction time (never from user input), eliminating the code-injection vector.
        #
        #   2. REMOVED: Watcher job (Start-ThreadJob wrapping Wait-Job).
        #      Replaced with Register-ObjectEvent on the job's StateChanged event.
        #      The event fires on the PowerShell event thread — zero watcher threads.
        #      Dispatcher.Invoke marshals UI updates back to the WPF thread correctly.
        #
        #   3. RENAMED: param($p, $s) -> param($__p__, $__action__).
        #      The original names collided with caller-supplied parameter keys
        #      (e.g. key 's' for search) unpacked by Set-Variable, overwriting $s
        #      before & $s could invoke the scriptblock.
        function Invoke-AsyncAction {
            param(
                [scriptblock]$ScriptBlock,
                [hashtable]$Parameters         = @{},
                [scriptblock]$OnCompleted,
                [scriptblock]$InitializationScript = {}
            )

            $SetBusy.Invoke($true)

            # -RunspacePool is intentionally omitted here.
            # The RunspacePool object on $state exists for future cross-call CIM session
            # wiring (see state_lazywinadmin.speq: cim_session PARTIAL) but passing it to
            # Start-ThreadJob causes a parameter-not-found error in PS 7 because the inbox
            # stub loaded by auto-discovery does not expose that named parameter.
            # Start-ThreadJob manages its own internal runspace allocation without it.
            try {
                $job = Start-ThreadJob `
                           -InitializationScript $InitializationScript `
                           -ArgumentList $Parameters, $ScriptBlock -ScriptBlock {
                    param($__p__, $__action__)
                    foreach ($key in $__p__.Keys) { Set-Variable -Name $key -Value $__p__[$key] }
                    & $__action__
                }
            }
            catch {
                # Start-ThreadJob itself failed (e.g. runspace quota, bad script reference).
                # Reset busy state and surface a safe message — do not re-throw into the WPF
                # dispatcher (re-throwing here kills ShowDialog).
                $errText = "[!] Could not start background job: $_"
                $window.Dispatcher.Invoke([action]{
                    $lblStatus.Text = $errText
                    $pbBusy.IsIndeterminate = $false
                })
                return
            }

            # All values needed inside Dispatcher.Invoke are captured into locals here.
            # This avoids $Event lifetime issues when the [action] delegate executes
            # on the WPF UI thread after the event-handler scope has returned.
            Register-ObjectEvent -InputObject $job -EventName StateChanged -MessageData @{
                Job      = $job
                Window   = $window
                Callback = $OnCompleted
                BusyFn   = $SetBusy
            } -Action {
                $jobState = $Event.SourceArgs[0].JobStateInfo.State
                if ($jobState -notin 'Completed', 'Failed', 'Stopped') { return }

                $res       = Receive-Job -Job $Event.MessageData.Job -ErrorAction SilentlyContinue
                $callback  = $Event.MessageData.Callback
                $busyFn    = $Event.MessageData.BusyFn
                $evtWindow = $Event.MessageData.Window
                $evtJob    = $Event.MessageData.Job
                $evtSrc    = $EventSubscriber.SourceIdentifier

                $evtWindow.Dispatcher.Invoke([action]{
                    & $callback $res
                    $busyFn.Invoke($false)
                })

                Unregister-Event -SourceIdentifier $evtSrc    -ErrorAction SilentlyContinue
                Remove-Job       -Job $evtJob -Force           -ErrorAction SilentlyContinue
            } | Out-Null
        }

        # --- GOVERNANCE HANDLERS ---
        $btnGetIntuneDevices.Add_Click({
            if (-not ($RequireCloudSession.Invoke())) { return }
            $search = $txtIntuneSearch.Text
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-IntuneDevice.ps1'")) `
                -Parameters  @{ s = $search } `
                -ScriptBlock { Get-IntuneDevice -Search $s } `
                -OnCompleted {
                    param($data)
                    $lvIntuneDevices.Items.Clear()
                    $data | ForEach-Object { $lvIntuneDevices.Items.Add($_) }
                }
        })

        $btnGetAzureSummary.Add_Click({
            if (-not ($RequireCloudSession.Invoke())) { return }
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-AzureResourceSummary.ps1'")) `
                -ScriptBlock { Get-AzureResourceSummary } `
                -OnCompleted {
                    param($data)
                    $lvAzureResources.Items.Clear()
                    $data | ForEach-Object { $lvAzureResources.Items.Add($_) }
                }
        })

        # --- IDENTITY HANDLERS (LOCAL) ---
        $btnGetLocalUsers.Add_Click({
            if (-not ($RequireComputerName.Invoke())) { return }
            $comp = $txtComputerName.Text
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ComputerLocalUser.ps1'")) `
                -Parameters  @{ t = $comp } `
                -ScriptBlock { Get-ComputerLocalUser -ComputerName $t } `
                -OnCompleted {
                    param($data)
                    $lvLocalAccounts.Items.Clear()
                    $data | ForEach-Object { $lvLocalAccounts.Items.Add($_) }
                }
        })

        $btnGetLocalGroups.Add_Click({
            if (-not ($RequireComputerName.Invoke())) { return }
            $comp = $txtComputerName.Text
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ComputerLocalGroup.ps1'")) `
                -Parameters  @{ t = $comp } `
                -ScriptBlock { Get-ComputerLocalGroup -ComputerName $t } `
                -OnCompleted {
                    param($data)
                    $lvLocalAccounts.Items.Clear()
                    $data | ForEach-Object { $lvLocalAccounts.Items.Add($_) }
                }
        })

        # --- IDENTITY HANDLERS (ENTRA) ---
        $btnGetEntraUsers.Add_Click({
            if (-not ($RequireCloudSession.Invoke())) { return }
            $search = $txtEntraSearch.Text
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-EntraIdentity.ps1'")) `
                -Parameters  @{ s = $search } `
                -ScriptBlock { Get-EntraIdentity -Type "User" -Search $s } `
                -OnCompleted {
                    param($data)
                    $lvEntraIdentity.Items.Clear()
                    $data | ForEach-Object { $lvEntraIdentity.Items.Add($_) }
                }
        })

        $btnGetEntraGroups.Add_Click({
            if (-not ($RequireCloudSession.Invoke())) { return }
            $search = $txtEntraSearch.Text
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-EntraIdentity.ps1'")) `
                -Parameters  @{ s = $search } `
                -ScriptBlock { Get-EntraIdentity -Type "Group" -Search $s } `
                -OnCompleted {
                    param($data)
                    $lvEntraIdentity.Items.Clear()
                    $data | ForEach-Object {
                        $item = $_
                        if ($item.Description) { $item.UserPrincipalName = $item.Description }
                        $lvEntraIdentity.Items.Add($item)
                    }
                }
        })

        # --- SYSTEM HANDLERS ---
        $btnPing.Add_Click({
            if (-not ($RequireComputerName.Invoke())) { return }
            $comp = $txtComputerName.Text
            Invoke-AsyncAction `
                -Parameters  @{ t = $comp } `
                -ScriptBlock {
                    # Test WinRM port 5985 — ICMP ping alone does not confirm remote management
                    # is available. This is the actual transport CIM uses.
                    $tcpTest = Test-NetConnection -ComputerName $t -Port 5985 -WarningAction SilentlyContinue
                    if ($tcpTest.TcpTestSucceeded) { "[OK] $t online (WinRM port 5985 reachable)" }
                    else                           { "[!] $t — WinRM port 5985 not reachable"     }
                } `
                -OnCompleted {
                    param($res) $AppendOutput.Invoke($res)
                }
        })

        $btnUptime.Add_Click({
            if (-not ($RequireComputerName.Invoke())) { return }
            $comp = $txtComputerName.Text
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ComputerUptime.ps1'")) `
                -Parameters  @{ t = $comp } `
                -ScriptBlock { Get-ComputerUptime -ComputerName $t } `
                -OnCompleted {
                    param($res) $AppendOutput.Invoke("[UPTIME] $res")
                }
        })

        $btnEnableRdp.Add_Click({
            if (-not ($RequireComputerName.Invoke())) { return }
            $comp = $txtComputerName.Text
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Set-ComputerRDP.ps1'")) `
                -Parameters  @{ t = $comp } `
                -ScriptBlock { Set-ComputerRDP -ComputerName $t -Enabled $true } `
                -OnCompleted {
                    param($res) $AppendOutput.Invoke("[RDP] $res")
                }
        })

        $btnDisableRdp.Add_Click({
            if (-not ($RequireComputerName.Invoke())) { return }
            $comp = $txtComputerName.Text
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Set-ComputerRDP.ps1'")) `
                -Parameters  @{ t = $comp } `
                -ScriptBlock { Set-ComputerRDP -ComputerName $t -Enabled $false } `
                -OnCompleted {
                    param($res) $AppendOutput.Invoke("[RDP] $res")
                }
        })

        # --- SERVICE HANDLERS ---
        $btnGetServices.Add_Click({
            if (-not ($RequireComputerName.Invoke())) { return }
            $comp   = $txtComputerName.Text
            $search = $txtServiceSearch.Text
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ComputerService.ps1'")) `
                -Parameters  @{ t = $comp; s = $search } `
                -ScriptBlock { Get-ComputerService -ComputerName $t -Name $s } `
                -OnCompleted {
                    param($data)
                    $lvServices.Items.Clear()
                    $data | ForEach-Object { $lvServices.Items.Add($_) }
                }
        })

        $btnGetStoppedAuto.Add_Click({
            if (-not ($RequireComputerName.Invoke())) { return }
            $comp = $txtComputerName.Text
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ComputerService.ps1'")) `
                -Parameters  @{ t = $comp } `
                -ScriptBlock { Get-ComputerService -ComputerName $t -OnlyAutoStopped } `
                -OnCompleted {
                    param($data)
                    $lvServices.Items.Clear()
                    $data | ForEach-Object { $lvServices.Items.Add($_) }
                }
        })

        # --- SOFTWARE HANDLERS ---
        $btnGetSoftware.Add_Click({
            if (-not ($RequireComputerName.Invoke())) { return }
            $comp   = $txtComputerName.Text
            $search = $txtSoftwareSearch.Text
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ComputerSoftware.ps1'")) `
                -Parameters  @{ t = $comp; s = $search } `
                -ScriptBlock { Get-ComputerSoftware -ComputerName $t -Search $s } `
                -OnCompleted {
                    param($data)
                    $lvSoftware.Items.Clear()
                    $data | ForEach-Object { $lvSoftware.Items.Add($_) }
                }
        })

        # --- HARDWARE HANDLERS ---
        $btnGetHardware.Add_Click({
            if (-not ($RequireComputerName.Invoke())) { return }
            $comp         = $txtComputerName.Text
            $hwInitScript = [scriptblock]::Create(
                ". '$PrivatePath\Get-ComputerHardware.ps1'; . '$PrivatePath\Get-ComputerMotherboard.ps1'"
            )
            Invoke-AsyncAction `
                -InitializationScript $hwInitScript `
                -Parameters  @{ t = $comp } `
                -ScriptBlock {
                    $hw   = Get-ComputerHardware   -ComputerName $t
                    $mobo = Get-ComputerMotherboard -ComputerName $t
                    return @{ hw = $hw; mobo = $mobo }
                } `
                -OnCompleted {
                    param($data)
                    if ($data.hw) {
                        $hw = $data.hw
                        $txtHwModel.Text  = "$($hw.Manufacturer) $($hw.Model)"
                        $txtHwSerial.Text = $hw.SerialNumber
                        $txtHwCpu.Text    = $hw.CPU
                        $txtHwRam.Text    = "$($hw.RAM_GB) GB"
                        $txtHwOs.Text     = $hw.OS
                        $lvHwDisks.Items.Clear()
                        $hw.Disks | ForEach-Object { $lvHwDisks.Items.Add($_) }
                    }
                    if ($data.mobo) {
                        $txtHwMobo.Text = "$($data.mobo.Product) ($($data.mobo.SerialNumber))"
                    }
                }
        })

        # --- NETWORK HANDLERS ---
        $btnGetNetwork.Add_Click({
            if (-not ($RequireComputerName.Invoke())) { return }
            $comp   = $txtComputerName.Text
            $onlyIP = $chkOnlyIPEnabled.IsChecked
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ComputerNetwork.ps1'")) `
                -Parameters  @{ t = $comp; o = $onlyIP } `
                -ScriptBlock { Get-ComputerNetwork -ComputerName $t -OnlyIPEnabled $o } `
                -OnCompleted {
                    param($data)
                    $lvNetwork.Items.Clear()
                    $data | ForEach-Object { $lvNetwork.Items.Add($_) }
                }
        })

        # --- REGISTRY HANDLERS ---
        $btnRegRead.Add_Click({
            if (-not ($RequireComputerName.Invoke())) { return }
            $comp = $txtComputerName.Text
            $hive = $cbRegHive.Text
            $path = $txtRegPath.Text
            $val  = $txtRegValueName.Text
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Invoke-ComputerRegistry.ps1'")) `
                -Parameters  @{ t = $comp; h = $hive; p = $path; v = $val } `
                -ScriptBlock { Invoke-ComputerRegistry -Action "Get" -ComputerName $t -Hive $h -KeyPath $p -ValueName $v } `
                -OnCompleted {
                    param($res)
                    $txtRegResult.Text = if ($null -ne $res) { "Value: $res" } else { "Value not found or error." }
                }
        })

        $btnRegWrite.Add_Click({
            if (-not ($RequireComputerName.Invoke())) { return }
            $comp = $txtComputerName.Text
            $hive = $cbRegHive.Text
            $path = $txtRegPath.Text
            $val  = $txtRegValueName.Text
            $data = $txtRegValueData.Text
            $type = $cbRegType.Text
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Invoke-ComputerRegistry.ps1'")) `
                -Parameters  @{ t = $comp; h = $hive; p = $path; v = $val; d = $data; ty = $type } `
                -ScriptBlock { Invoke-ComputerRegistry -Action "Set" -ComputerName $t -Hive $h -KeyPath $p -ValueName $v -Value $d -ValueType $ty } `
                -OnCompleted {
                    param($res)
                    $txtRegResult.Text = if ($res) { "Success: Value written." } else { "Error: Failed to write value." }
                }
        })

        $btnRegDelete.Add_Click({
            if (-not ($RequireComputerName.Invoke())) { return }
            $comp = $txtComputerName.Text
            $hive = $cbRegHive.Text
            $path = $txtRegPath.Text
            $val  = $txtRegValueName.Text
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Invoke-ComputerRegistry.ps1'")) `
                -Parameters  @{ t = $comp; h = $hive; p = $path; v = $val } `
                -ScriptBlock { Invoke-ComputerRegistry -Action "Remove" -ComputerName $t -Hive $h -KeyPath $p -ValueName $v } `
                -OnCompleted {
                    param($res)
                    $txtRegResult.Text = if ($res) { "Success: Item removed." } else { "Error: Failed to remove item." }
                }
        })

        # --- ACTIVE DIRECTORY HANDLERS ---
        # Requires RSAT (rsat-ad-ds) on the machine running LazyWinAdmin.
        # AdFilter is the canonical search term — single-letter variables are forbidden by VOCABULARY.
        $btnGetAdComputer.Add_Click({
            $comp     = $txtComputerName.Text
            $adFilter = $txtAdSearch.Text
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ComputerADInfo.ps1'")) `
                -Parameters  @{ t = $comp; af = $adFilter } `
                -ScriptBlock { Get-ComputerADInfo -Type "Computer" -ComputerName $t -AdFilter $af } `
                -OnCompleted {
                    param($data)
                    $lvAdResults.Items.Clear()
                    $data | ForEach-Object { $lvAdResults.Items.Add($_) }
                }
        })

        $btnGetAdUsers.Add_Click({
            $adFilter = $txtAdSearch.Text
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ComputerADInfo.ps1'")) `
                -Parameters  @{ af = $adFilter } `
                -ScriptBlock { Get-ComputerADInfo -Type "User" -AdFilter $af } `
                -OnCompleted {
                    param($data)
                    $lvAdResults.Items.Clear()
                    $data | ForEach-Object { $lvAdResults.Items.Add($_) }
                }
        })

        $btnGetAdGroups.Add_Click({
            $adFilter = $txtAdSearch.Text
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ComputerADInfo.ps1'")) `
                -Parameters  @{ af = $adFilter } `
                -ScriptBlock { Get-ComputerADInfo -Type "Group" -AdFilter $af } `
                -OnCompleted {
                    param($data)
                    $lvAdResults.Items.Clear()
                    $data | ForEach-Object { $lvAdResults.Items.Add($_) }
                }
        })

        # --- CLOUD AUTH HANDLER ---
        $btnCloudLogin.Add_Click({
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Connect-ModernCloud.ps1'")) `
                -ScriptBlock { Connect-ModernCloud -Interactive } `
                -OnCompleted {
                    param($res)
                    $connected = $res -match "^\[OK\]"
                    # Persist auth state so $RequireCloudSession guards can read it
                    $state.SyncHash.CloudConnected = $connected
                    $lblCloudStatus.Text       = $res
                    $lblCloudStatus.Foreground = if ($connected) {
                        [System.Windows.Media.Brushes]::Green
                    } else {
                        [System.Windows.Media.Brushes]::Red
                    }
                    $lblStatus.Text = if ($connected) { "Cloud: connected" } else { "Cloud: not connected" }
                }
        })

        # Service Principal login — TenantId/ClientId sourced from UI text boxes.
        # ClientSecret is read from a PasswordBox (.SecurePassword) — never stored as plaintext.
        # Secrets are scoped to CLOUD layer per lazywinadmin.speq SECRETS block.
        $btnCloudConnectSP.Add_Click({
            $tenantId     = $txtTenantId.Text
            $clientId     = $txtClientId.Text
            $clientSecret = $txtClientSecret.SecurePassword   # SecureString — never .Password
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Connect-ModernCloud.ps1'")) `
                -Parameters  @{ tid = $tenantId; cid = $clientId; cs = $clientSecret } `
                -ScriptBlock { Connect-ModernCloud -TenantId $tid -ClientId $cid -ClientSecret $cs } `
                -OnCompleted {
                    param($res)
                    $connected = $res -match "^\[OK\]"
                    # Persist auth state so $RequireCloudSession guards can read it
                    $state.SyncHash.CloudConnected = $connected
                    $lblCloudStatus.Text       = $res
                    $lblCloudStatus.Foreground = if ($connected) {
                        [System.Windows.Media.Brushes]::Green
                    } else {
                        [System.Windows.Media.Brushes]::Red
                    }
                    $lblStatus.Text = if ($connected) { "Cloud: connected" } else { "Cloud: not connected" }
                }
        })

        $window.ShowDialog() | Out-Null
    }
    catch {
        Write-Warning "Failed to start LazyWinAdmin: $_"
    }
    finally {
        $state.Dispose()
    }
}
