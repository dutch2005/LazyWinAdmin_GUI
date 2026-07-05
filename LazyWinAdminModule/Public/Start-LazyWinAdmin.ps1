function Start-LazyWinAdmin {
    <#
    .SYNOPSIS
        Starts the modernized WPF-based LazyWinAdmin GUI.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param ()

    if (-not $PSCmdlet.ShouldProcess('LazyWinAdmin GUI', 'Start')) {
        return
    }

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

        # Intune Scripts controls
        $btnGetIntuneScripts         = $window.FindName("btnGetIntuneScripts")
        $txtIntuneScriptSearch       = $window.FindName("txtIntuneScriptSearch")
        $txtIntuneScriptDownloadPath = $window.FindName("txtIntuneScriptDownloadPath")
        $btnDownloadIntuneScripts    = $window.FindName("btnDownloadIntuneScripts")
        $lvIntuneScripts             = $window.FindName("lvIntuneScripts")

        # Device Compliance controls
        $btnCheckCompliance  = $window.FindName("btnCheckCompliance")
        $lvComplianceStatus  = $window.FindName("lvComplianceStatus")
        $btnFixLocation      = $window.FindName("btnFixLocation")
        $btnFixOutlookImages = $window.FindName("btnFixOutlookImages")
        $btnRemoveOneDrive   = $window.FindName("btnRemoveOneDrive")
        $txtUpdateHoursStart = $window.FindName("txtUpdateHoursStart")
        $txtUpdateHoursEnd   = $window.FindName("txtUpdateHoursEnd")
        $btnFixUpdateHours   = $window.FindName("btnFixUpdateHours")
        $txtComplianceOutput = $window.FindName("txtComplianceOutput")

        # Exchange controls
        $txtExchangeUpn         = $window.FindName("txtExchangeUpn")
        $btnConnectExchange     = $window.FindName("btnConnectExchange")
        $lblExchangeStatus      = $window.FindName("lblExchangeStatus")
        $btnGetMailboxPerms     = $window.FindName("btnGetMailboxPerms")
        $txtExchangeViewUser    = $window.FindName("txtExchangeViewUser")
        $lvMailboxPerms         = $window.FindName("lvMailboxPerms")
        $txtExchangeSourceUser  = $window.FindName("txtExchangeSourceUser")
        $txtExchangeTargetUser  = $window.FindName("txtExchangeTargetUser")
        $btnMirrorMailboxPerms  = $window.FindName("btnMirrorMailboxPerms")
        $txtExchangeMailbox     = $window.FindName("txtExchangeMailbox")
        $txtExchangeGrantUser   = $window.FindName("txtExchangeGrantUser")
        $btnGrantMailboxPerms   = $window.FindName("btnGrantMailboxPerms")

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
        $lblAdminStatus    = $window.FindName("lblAdminStatus")
        $btnRestartAdmin   = $window.FindName("btnRestartAdmin")
        $pbBusy            = $window.FindName("pbBusy")
        $lblTime           = $window.FindName("lblTime")

        # Service control and export controls (v1.3.0)
        $lblServicesCount       = $window.FindName("lblServicesCount")
        $btnStartService        = $window.FindName("btnStartService")
        $btnStopService         = $window.FindName("btnStopService")
        $btnRestartService      = $window.FindName("btnRestartService")
        $btnExportServices      = $window.FindName("btnExportServices")
        $lblSoftwareCount       = $window.FindName("lblSoftwareCount")
        $btnExportSoftware      = $window.FindName("btnExportSoftware")
        $lblNetworkCount        = $window.FindName("lblNetworkCount")
        $btnExportNetwork       = $window.FindName("btnExportNetwork")
        $lblIntuneDevicesCount  = $window.FindName("lblIntuneDevicesCount")
        $btnExportIntuneDevices = $window.FindName("btnExportIntuneDevices")
        $lblMailboxPermsCount   = $window.FindName("lblMailboxPermsCount")
        $btnExportMailboxPerms  = $window.FindName("btnExportMailboxPerms")

        # --- ADMIN ELEVATION CHECK ---
        # Detect whether this process is running with local administrator rights.
        # Stored as a plain bool — read-only, UI thread only, no sync needed.
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        if ($isAdmin) {
            $lblAdminStatus.Text       = 'Administrator'
            $lblAdminStatus.Foreground = [System.Windows.Media.Brushes]::Green
            $btnRestartAdmin.Visibility = [System.Windows.Visibility]::Collapsed
            $window.Title = 'LazyWinAdmin - Modernized 2026 [Administrator]'
        }
        else {
            # lblAdminStatus and btnRestartAdmin keep their XAML defaults (visible + amber)
            $window.Title = 'LazyWinAdmin - Modernized 2026'
        }

        # Relaunch this session elevated. Resolves the module manifest path relative to
        # this script file so the new elevated window loads the same module.
        $btnRestartAdmin.Add_Click({
            $psd1 = Resolve-Path (Join-Path $PSScriptRoot '..\LazyWinAdminModule.psd1')
            try {
                Start-Process -FilePath 'pwsh.exe' `
                    -ArgumentList "-NoProfile -Command `"Import-Module '$psd1' -Force; Start-LazyWinAdmin`"" `
                    -Verb RunAs
                $window.Close()
            }
            catch {
                # User cancelled the UAC prompt — just show a status note.
                $lblStatus.Text = '[!] Elevation cancelled.'
            }
        })

        # Default Value
        $txtComputerName.Text = $env:COMPUTERNAME

        # --- UI HELPERS ---
        # CheckAccess() returns $true when already on the UI thread — execute directly.
        # From a background / event thread it returns $false — marshal via Dispatcher.Invoke.
        # Skipping the Invoke when already on the UI thread prevents re-entrant
        # DispatcherFrame pushes that cause the application to freeze.
        $AppendOutput = {
            param($text)
            if ($window.Dispatcher.CheckAccess()) {
                $txtOutput.AppendText("$text`n")
                $txtOutput.ScrollToEnd()
            } else {
                $window.Dispatcher.Invoke([action]{
                    $txtOutput.AppendText("$text`n")
                    $txtOutput.ScrollToEnd()
                })
            }
        }

        $SetBusy = {
            param([bool]$isBusy)
            # Track busy state in SyncHash so event-thread code can read it without touching UI
            $state.SyncHash.IsBusy = $isBusy
            if ($window.Dispatcher.CheckAccess()) {
                $pbBusy.IsIndeterminate = $isBusy
                $lblStatus.Text = if ($isBusy) { "Working..." } else { "Ready" }
            } else {
                $window.Dispatcher.Invoke([action]{
                    $pbBusy.IsIndeterminate = $isBusy
                    $lblStatus.Text = if ($isBusy) { "Working..." } else { "Ready" }
                })
            }
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

        # Checks that Exchange Online is connected.
        # Must be called before any button handler that calls Exchange cmdlets.
        $RequireExchangeSession = {
            if (-not $state.SyncHash.ExchangeConnected) {
                $lblStatus.Text = "[!] Exchange not connected — use the Exchange › Connection tab first."
                return $false
            }
            return $true
        }

        # Appends an admin-rights hint to the output box when all three are true:
        #   1. The operation returned no results (null/empty data)
        #   2. The process is not elevated
        #   3. The target is the local machine (localhost / 127.0.0.1 / $env:COMPUTERNAME)
        # Called from OnCompleted handlers for features that require local admin.
        $AdminHint = {
            param([string]$computer)
            $isLocalTarget = ($computer -ieq 'localhost'   -or
                              $computer -ieq '127.0.0.1'   -or
                              $computer -ieq $env:COMPUTERNAME)
            if (-not $isAdmin -and $isLocalTarget) {
                $AppendOutput.Invoke(
                    "[!] No results returned. This feature requires local Administrator rights." +
                    " Use the 'Restart as Admin' button in the status bar to relaunch elevated."
                )
            }
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
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
                'PSUseUsingScopeModifierInNewRunspaces', '',
                Justification = '$__p__ and $__action__ are param() in the ScriptBlock; $key is a foreach variable — all declared within the block')]
            param(
                [scriptblock]$ScriptBlock,
                [hashtable]$Parameters             = @{},
                [scriptblock]$OnCompleted,
                [scriptblock]$InitializationScript = {}
            )

            $SetBusy.Invoke($true)

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
                # Runs on UI thread — update directly, no Dispatcher.Invoke needed.
                $lblStatus.Text         = "[!] Could not start background job: $_"
                $pbBusy.IsIndeterminate = $false
                $state.SyncHash.IsBusy  = $false
                return
            }

            # When the job finishes, enqueue the result for the DispatcherTimer to process
            # on the WPF UI thread.  This avoids Dispatcher.Invoke/InvokeAsync entirely,
            # eliminating all re-entrant DispatcherFrame and cross-thread closure issues.
            Register-ObjectEvent -InputObject $job -EventName StateChanged -MessageData @{
                Job      = $job
                Queue    = $state.SyncHash.UIQueue
                Callback = $OnCompleted
                BusyFn   = $SetBusy
            } -Action {
                $jobState = $Event.SourceArgs[0].JobStateInfo.State
                if ($jobState -notin 'Completed', 'Failed', 'Stopped') { return }

                $res    = Receive-Job -Job $Event.MessageData.Job -ErrorAction SilentlyContinue
                $evtSrc = $EventSubscriber.SourceIdentifier
                $evtJob = $Event.MessageData.Job

                $Event.MessageData.Queue.Enqueue([PSCustomObject]@{
                    Callback = $Event.MessageData.Callback
                    Result   = $res
                    BusyFn   = $Event.MessageData.BusyFn
                })

                Unregister-Event -SourceIdentifier $evtSrc -ErrorAction SilentlyContinue
                Remove-Job       -Job $evtJob -Force        -ErrorAction SilentlyContinue
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
                    $lblIntuneDevicesCount.Text = "$($lvIntuneDevices.Items.Count) device(s)"
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
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Test-ComputerPort.ps1'")) `
                -Parameters  @{ t = $comp } `
                -ScriptBlock {
                    # Test WinRM port 5985 — ICMP ping alone does not confirm remote management
                    # is available. This is the actual transport CIM uses.
                    $result = Test-ComputerPort -ComputerName $t -Port 5985 -TimeoutMs 3000
                    if ($result -eq 'Open') { "[OK] $t online (WinRM port 5985 reachable)" }
                    else                    { "[!] $t — WinRM port 5985 not reachable ($result)" }
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
                    param($res)
                    $AppendOutput.Invoke("[RDP] $res")
                    if ($res -match '^Error:') { $AdminHint.Invoke($comp) }
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
                    param($res)
                    $AppendOutput.Invoke("[RDP] $res")
                    if ($res -match '^Error:') { $AdminHint.Invoke($comp) }
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
                    $lblServicesCount.Text = "$($lvServices.Items.Count) service(s)"
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
                    $lblServicesCount.Text = "$($lvServices.Items.Count) service(s)"
                }
        })

        $btnStartService.Add_Click({
            if (-not ($RequireComputerName.Invoke())) { return }
            $selected = $lvServices.SelectedItem
            if ($null -eq $selected) {
                $lblStatus.Text = "[!] Select a service from the list first."
                return
            }
            $comp    = $txtComputerName.Text
            $svcName = $selected.Name
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Invoke-ComputerServiceControl.ps1'")) `
                -Parameters  @{ computerName = $comp; serviceName = $svcName; action = 'Start' } `
                -ScriptBlock { Invoke-ComputerServiceControl -ComputerName $computerName -ServiceName $serviceName -Action $action } `
                -OnCompleted {
                    param($res)
                    $AppendOutput.Invoke("[Service] $res")
                    $lblStatus.Text = $res
                    if ($res -match '^Error:') { $AdminHint.Invoke($comp) }
                }
        })

        $btnStopService.Add_Click({
            if (-not ($RequireComputerName.Invoke())) { return }
            $selected = $lvServices.SelectedItem
            if ($null -eq $selected) {
                $lblStatus.Text = "[!] Select a service from the list first."
                return
            }
            $comp    = $txtComputerName.Text
            $svcName = $selected.Name
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Invoke-ComputerServiceControl.ps1'")) `
                -Parameters  @{ computerName = $comp; serviceName = $svcName; action = 'Stop' } `
                -ScriptBlock { Invoke-ComputerServiceControl -ComputerName $computerName -ServiceName $serviceName -Action $action } `
                -OnCompleted {
                    param($res)
                    $AppendOutput.Invoke("[Service] $res")
                    $lblStatus.Text = $res
                    if ($res -match '^Error:') { $AdminHint.Invoke($comp) }
                }
        })

        $btnRestartService.Add_Click({
            if (-not ($RequireComputerName.Invoke())) { return }
            $selected = $lvServices.SelectedItem
            if ($null -eq $selected) {
                $lblStatus.Text = "[!] Select a service from the list first."
                return
            }
            $comp    = $txtComputerName.Text
            $svcName = $selected.Name
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Invoke-ComputerServiceControl.ps1'")) `
                -Parameters  @{ computerName = $comp; serviceName = $svcName; action = 'Restart' } `
                -ScriptBlock { Invoke-ComputerServiceControl -ComputerName $computerName -ServiceName $serviceName -Action $action } `
                -OnCompleted {
                    param($res)
                    $AppendOutput.Invoke("[Service] $res")
                    $lblStatus.Text = $res
                    if ($res -match '^Error:') { $AdminHint.Invoke($comp) }
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
                    $lblSoftwareCount.Text = "$($lvSoftware.Items.Count) application(s)"
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
                    else {
                        $AdminHint.Invoke($comp)
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
                    $lblNetworkCount.Text = "$($lvNetwork.Items.Count) adapter(s)"
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
                    if ($res) {
                        $txtRegResult.Text = "Success: Value written."
                    }
                    else {
                        $txtRegResult.Text = "Error: Failed to write value."
                        $AdminHint.Invoke($comp)
                    }
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
                    if ($res) {
                        $txtRegResult.Text = "Success: Item removed."
                    }
                    else {
                        $txtRegResult.Text = "Error: Failed to remove item."
                        $AdminHint.Invoke($comp)
                    }
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

        # --- INTUNE SCRIPTS HANDLERS ---
        $btnGetIntuneScripts.Add_Click({
            if (-not ($RequireCloudSession.Invoke())) { return }
            $search = $txtIntuneScriptSearch.Text
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-IntuneManagementScript.ps1'")) `
                -Parameters  @{ s = $search } `
                -ScriptBlock { Get-IntuneManagementScript -Search $s } `
                -OnCompleted {
                    param($data)
                    $lvIntuneScripts.Items.Clear()
                    if ($data) {
                        $data | ForEach-Object { $lvIntuneScripts.Items.Add($_) }
                        $AppendOutput.Invoke("[Intune Scripts] $($data.Count) script(s) listed.")
                    } else {
                        $AppendOutput.Invoke("[Intune Scripts] No scripts found or not connected to Graph.")
                    }
                }
        })

        $btnDownloadIntuneScripts.Add_Click({
            if (-not ($RequireCloudSession.Invoke())) { return }
            $search       = $txtIntuneScriptSearch.Text
            $downloadPath = $txtIntuneScriptDownloadPath.Text
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-IntuneManagementScript.ps1'")) `
                -Parameters  @{ s = $search; dp = $downloadPath } `
                -ScriptBlock { Get-IntuneManagementScript -Search $s -DownloadPath $dp } `
                -OnCompleted {
                    param($data)
                    $lvIntuneScripts.Items.Clear()
                    if ($data) {
                        $data | ForEach-Object { $lvIntuneScripts.Items.Add($_) }
                        $AppendOutput.Invoke("[Intune Scripts] $($data.Count) script(s) downloaded to $downloadPath.")
                    } else {
                        $AppendOutput.Invoke("[Intune Scripts] No scripts found or not connected to Graph.")
                    }
                }
        })

        # --- DEVICE COMPLIANCE HANDLERS ---
        $btnCheckCompliance.Add_Click({
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-DeviceComplianceStatus.ps1'")) `
                -ScriptBlock { Get-DeviceComplianceStatus } `
                -OnCompleted {
                    param($data)
                    $lvComplianceStatus.Items.Clear()
                    $data | ForEach-Object { $lvComplianceStatus.Items.Add($_) }
                }
        })

        $btnFixLocation.Add_Click({
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Set-DeviceComplianceItem.ps1'")) `
                -ScriptBlock { Set-DeviceComplianceItem -Item 'LocationServices' } `
                -OnCompleted {
                    param($res)
                    $txtComplianceOutput.Text = $res
                    if ($res -match '^Error:') { $AdminHint.Invoke($env:COMPUTERNAME) }
                }
        })

        $btnFixOutlookImages.Add_Click({
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Set-DeviceComplianceItem.ps1'")) `
                -ScriptBlock { Set-DeviceComplianceItem -Item 'OutlookExternalImages' } `
                -OnCompleted {
                    param($res)
                    $txtComplianceOutput.Text = $res
                }
        })

        $btnRemoveOneDrive.Add_Click({
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Set-DeviceComplianceItem.ps1'")) `
                -ScriptBlock { Set-DeviceComplianceItem -Item 'RemoveOneDrive' } `
                -OnCompleted {
                    param($res)
                    $txtComplianceOutput.Text = $res
                    if ($res -match '^Error:') { $AdminHint.Invoke($env:COMPUTERNAME) }
                }
        })

        $btnFixUpdateHours.Add_Click({
            $startHour = 0
            $endHour   = 0
            if (-not [int]::TryParse($txtUpdateHoursStart.Text, [ref]$startHour) -or
                -not [int]::TryParse($txtUpdateHoursEnd.Text,   [ref]$endHour)   -or
                $startHour -lt 0 -or $startHour -gt 23 -or
                $endHour   -lt 0 -or $endHour   -gt 23) {
                $txtComplianceOutput.Text = "[!] Start and End hours must be integers between 0 and 23."
                return
            }
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Set-DeviceComplianceItem.ps1'")) `
                -Parameters  @{ sh = $startHour; eh = $endHour } `
                -ScriptBlock { Set-DeviceComplianceItem -Item 'WindowsUpdateActiveHours' -ActiveHoursStart $sh -ActiveHoursEnd $eh } `
                -OnCompleted {
                    param($res)
                    $txtComplianceOutput.Text = $res
                    if ($res -match '^Error:') { $AdminHint.Invoke($env:COMPUTERNAME) }
                }
        })

        # --- EXCHANGE HANDLERS ---
        $btnConnectExchange.Add_Click({
            $upn = $txtExchangeUpn.Text
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Connect-ExchangeSession.ps1'")) `
                -Parameters  @{ u = $upn } `
                -ScriptBlock { Connect-ExchangeSession -UserPrincipalName $u } `
                -OnCompleted {
                    param($res)
                    $connected = $res -match '^\[OK\]'
                    $state.SyncHash.ExchangeConnected = $connected
                    $lblExchangeStatus.Text       = $res
                    $lblExchangeStatus.Foreground  = if ($connected) {
                        [System.Windows.Media.Brushes]::Green
                    } else {
                        [System.Windows.Media.Brushes]::Red
                    }
                    $lblStatus.Text = if ($connected) { "Exchange: connected" } else { "Exchange: not connected" }
                }
        })

        $btnGetMailboxPerms.Add_Click({
            if (-not ($RequireExchangeSession.Invoke())) { return }
            $upn = $txtExchangeViewUser.Text
            if ([string]::IsNullOrWhiteSpace($upn)) {
                $lblStatus.Text = "[!] Enter a User Principal Name to look up."
                return
            }
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ExchangeMailboxPermission.ps1'")) `
                -Parameters  @{ u = $upn } `
                -ScriptBlock { Get-ExchangeMailboxPermission -UserPrincipalName $u } `
                -OnCompleted {
                    param($data)
                    $lvMailboxPerms.Items.Clear()
                    if ($data) {
                        $data | ForEach-Object { $lvMailboxPerms.Items.Add($_) }
                        $lblMailboxPermsCount.Text = "$($lvMailboxPerms.Items.Count) mailbox(es)"
                    } else {
                        $lblMailboxPermsCount.Text = "0 mailbox(es)"
                        $AppendOutput.Invoke("[Exchange] No shared mailbox permissions found for $(Hide-UpnLocalPart $upn).")
                    }
                }
        })

        $btnMirrorMailboxPerms.Add_Click({
            if (-not ($RequireExchangeSession.Invoke())) { return }
            $src = $txtExchangeSourceUser.Text
            $tgt = $txtExchangeTargetUser.Text
            if ([string]::IsNullOrWhiteSpace($src) -or [string]::IsNullOrWhiteSpace($tgt)) {
                $lblStatus.Text = "[!] Enter both source and target UPNs for mirror."
                return
            }
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Set-ExchangeMailboxPermission.ps1'")) `
                -Parameters  @{ src = $src; tgt = $tgt } `
                -ScriptBlock { Set-ExchangeMailboxPermission -SourceUser $src -TargetUser $tgt } `
                -OnCompleted {
                    param($res)
                    $AppendOutput.Invoke("[Exchange Mirror] $res")
                    $lblStatus.Text = $res
                }
        })

        $btnGrantMailboxPerms.Add_Click({
            if (-not ($RequireExchangeSession.Invoke())) { return }
            $mb   = $txtExchangeMailbox.Text
            $user = $txtExchangeGrantUser.Text
            if ([string]::IsNullOrWhiteSpace($mb) -or [string]::IsNullOrWhiteSpace($user)) {
                $lblStatus.Text = "[!] Enter both a mailbox address and a user UPN."
                return
            }
            Invoke-AsyncAction `
                -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Set-ExchangeMailboxPermission.ps1'")) `
                -Parameters  @{ mb = $mb; u = $user } `
                -ScriptBlock { Set-ExchangeMailboxPermission -Mailbox $mb -User $u } `
                -OnCompleted {
                    param($res)
                    $AppendOutput.Invoke("[Exchange Grant] $res")
                    $lblStatus.Text = $res
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

        # --- EXPORT CSV HELPER ---
        # Opens a SaveFileDialog and writes all ListView items to a UTF-8 CSV file.
        # Runs synchronously on the UI thread — no async needed (file dialog is modal).
        $ExportListViewToCsv = {
            param([System.Windows.Controls.ListView]$lv, [string]$defaultName)
            if ($lv.Items.Count -eq 0) {
                $lblStatus.Text = "[!] No data to export — run a query first."
                return
            }
            $dialog            = [Microsoft.Win32.SaveFileDialog]::new()
            $dialog.Filter     = "CSV Files (*.csv)|*.csv"
            $dialog.FileName   = $defaultName
            $dialog.DefaultExt = ".csv"
            if ($dialog.ShowDialog() -eq $true) {
                try {
                    $lv.Items | Export-Csv -Path $dialog.FileName -NoTypeInformation -Encoding UTF8 -Force
                    $lblStatus.Text = "Exported $($lv.Items.Count) row(s) to $($dialog.FileName)"
                    $AppendOutput.Invoke("[Export] Saved $($lv.Items.Count) row(s) to $($dialog.FileName)")
                }
                catch {
                    $lblStatus.Text = "[!] Export failed: $($_.Exception.Message)"
                }
            }
        }

        $btnExportServices.Add_Click({
            $ExportListViewToCsv.Invoke($lvServices, "services_$($txtComputerName.Text)_$(Get-Date -Format yyyyMMdd).csv")
        })
        $btnExportSoftware.Add_Click({
            $ExportListViewToCsv.Invoke($lvSoftware, "software_$($txtComputerName.Text)_$(Get-Date -Format yyyyMMdd).csv")
        })
        $btnExportNetwork.Add_Click({
            $ExportListViewToCsv.Invoke($lvNetwork, "network_$($txtComputerName.Text)_$(Get-Date -Format yyyyMMdd).csv")
        })
        $btnExportIntuneDevices.Add_Click({
            $ExportListViewToCsv.Invoke($lvIntuneDevices, "intune_devices_$(Get-Date -Format yyyyMMdd).csv")
        })
        $btnExportMailboxPerms.Add_Click({
            $ExportListViewToCsv.Invoke($lvMailboxPerms, "mailbox_perms_$(Get-Date -Format yyyyMMdd).csv")
        })

        # --- CLIPBOARD CONTEXT MENUS ---
        # Right-click any ListView row → "Copy Row to Clipboard" (tab-separated values).
        # Uses PlacementTarget from the ContextMenu to avoid closure variable capture issues.
        foreach ($lv in @($lvServices, $lvSoftware, $lvNetwork, $lvLocalAccounts,
                           $lvEntraIdentity, $lvAdResults, $lvIntuneDevices, $lvIntuneScripts,
                           $lvHwDisks, $lvComplianceStatus, $lvMailboxPerms, $lvAzureResources)) {
            $ctxMenu  = [System.Windows.Controls.ContextMenu]::new()
            $copyItem = [System.Windows.Controls.MenuItem]::new()
            $copyItem.Header = "Copy Row to Clipboard"
            $copyItem.Add_Click({
                $listView = $this.Parent.PlacementTarget
                if ($null -ne $listView.SelectedItem) {
                    $values = $listView.SelectedItem.PSObject.Properties |
                              Where-Object { $_.MemberType -eq 'NoteProperty' } |
                              ForEach-Object { $_.Value }
                    [System.Windows.Clipboard]::SetText(($values -join "`t"))
                }
            })
            $ctxMenu.Items.Add($copyItem) | Out-Null
            $lv.ContextMenu = $ctxMenu
        }

        # DispatcherTimer — drains the UI callback queue on the WPF thread every 50 ms.
        # Background jobs enqueue their results via Register-ObjectEvent actions.
        # The timer dequeues and calls OnCompleted callbacks here, on the UI thread,
        # with full access to all WPF controls — no Dispatcher.Invoke needed in callbacks.
        $uiTimer          = [System.Windows.Threading.DispatcherTimer]::new()
        $uiTimer.Interval = [TimeSpan]::FromMilliseconds(50)
        $uiTimer.Add_Tick({
            $workItem = $null
            while ($state.SyncHash.UIQueue.TryDequeue([ref]$workItem)) {
                try   { & $workItem.Callback $workItem.Result }
                catch { $AppendOutput.Invoke("[!] UI callback error: $_") }
                finally { $workItem.BusyFn.Invoke($false) }
            }
        })
        $uiTimer.Start()

        # Clock timer — updates the status bar time display every second.
        $clockTimer          = [System.Windows.Threading.DispatcherTimer]::new()
        $clockTimer.Interval = [TimeSpan]::FromSeconds(1)
        $clockTimer.Add_Tick({ $lblTime.Text = (Get-Date).ToString('HH:mm:ss') })
        $clockTimer.Start()

        $window.ShowDialog() | Out-Null
    }
    catch {
        Write-Warning "Failed to start LazyWinAdmin: $_"
    }
    finally {
        $state.Dispose()
    }
}
