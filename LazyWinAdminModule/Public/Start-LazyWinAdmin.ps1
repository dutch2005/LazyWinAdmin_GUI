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

    try {
        # Load XAML
        $xamlPath = Join-Path $PSScriptRoot "..\UI\MainView.xaml"
        $xamlContent = Get-Content -Path $xamlPath -Raw

        $xmlReader = [System.Xml.XmlNodeReader]::new([System.Xml.XmlDocument]::new().LoadXml($xamlContent))
        $window = [System.Windows.Markup.XamlReader]::Load($xmlReader)

        # --- FIND CONTROLS ---
        $txtComputerName = $window.FindName("txtComputerName")
        $btnPing = $window.FindName("btnPing")
        $btnUptime = $window.FindName("btnUptime")
        $btnEnableRdp = $window.FindName("btnEnableRdp")
        $btnDisableRdp = $window.FindName("btnDisableRdp")
        $txtOutput = $window.FindName("txtOutput")
        
        $btnGetServices = $window.FindName("btnGetServices")
        $btnGetStoppedAuto = $window.FindName("btnGetStoppedAuto")
        $lvServices = $window.FindName("lvServices")
        $txtServiceSearch = $window.FindName("txtServiceSearch")

        $btnGetSoftware = $window.FindName("btnGetSoftware")
        $lvSoftware = $window.FindName("lvSoftware")
        $txtSoftwareSearch = $window.FindName("txtSoftwareSearch")

        $btnGetHardware = $window.FindName("btnGetHardware")
        $txtHwModel = $window.FindName("txtHwModel")
        $txtHwSerial = $window.FindName("txtHwSerial")
        $txtHwCpu = $window.FindName("txtHwCpu")
        $txtHwRam = $window.FindName("txtHwRam")
        $txtHwOs = $window.FindName("txtHwOs")
        $txtHwMobo = $window.FindName("txtHwMobo")
        $lvHwDisks = $window.FindName("lvHwDisks")

        $btnGetNetwork = $window.FindName("btnGetNetwork")
        $chkOnlyIPEnabled = $window.FindName("chkOnlyIPEnabled")
        $lvNetwork = $window.FindName("lvNetwork")

        $btnGetLocalUsers = $window.FindName("btnGetLocalUsers")
        $btnGetLocalGroups = $window.FindName("btnGetLocalGroups")
        $lvLocalAccounts = $window.FindName("lvLocalAccounts")
        $btnGetEntraUsers = $window.FindName("btnGetEntraUsers")
        $btnGetEntraGroups = $window.FindName("btnGetEntraGroups")
        $lvEntraIdentity = $window.FindName("lvEntraIdentity")
        $txtEntraSearch = $window.FindName("txtEntraSearch")

        # Governance Controls
        $btnGetIntuneDevices = $window.FindName("btnGetIntuneDevices")
        $lvIntuneDevices = $window.FindName("lvIntuneDevices")
        $txtIntuneSearch = $window.FindName("txtIntuneSearch")
        $btnGetAzureSummary = $window.FindName("btnGetAzureSummary")
        $lvAzureResources = $window.FindName("lvAzureResources")

        $btnRegRead = $window.FindName("btnRegRead")
        $btnRegWrite = $window.FindName("btnRegWrite")
        $btnRegDelete = $window.FindName("btnRegDelete")
        $cbRegHive = $window.FindName("cbRegHive")
        $cbRegType = $window.FindName("cbRegType")
        $txtRegValueName = $window.FindName("txtRegValueName")
        $txtRegValueData = $window.FindName("txtRegValueData")
        $txtRegPath = $window.FindName("txtRegPath")
        $txtRegResult = $window.FindName("txtRegResult")

        $btnCloudLogin = $window.FindName("btnCloudLogin")
        $lblCloudStatus = $window.FindName("lblCloudStatus")

        $lblStatus = $window.FindName("lblStatus")
        $pbBusy = $window.FindName("pbBusy")

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

        # --- ASYNC HELPER ---
        # This function handles starting a thread job and updating the UI when done without blocking.
        function Invoke-AsyncAction {
            param(
                [scriptblock]$ScriptBlock,
                [hashtable]$Args = @{},
                [scriptblock]$OnCompleted
            )
            
            $SetBusy.Invoke($true)
            
            # Use PowerShell 7 Start-ThreadJob for efficiency
            $job = Start-ThreadJob -RunspacePool $state.RunspacePool -ArgumentList $Args, $ScriptBlock -ScriptBlock {
                param($a, $s)
                # Unpack arguments into scope
                foreach ($key in $a.Keys) { Set-Variable -Name $key -Value $a[$key] }
                & $s
            }

            # Poll for completion without blocking the UI thread
            # In a real WPF app we'd use events, here we use a timer or a simple loop with DoEvents
            # But since we're in PowerShell, we'll use a simplified 'Wait-Job' with a tiny timeout or just Register-ObjectEvent
            # Actually, the simplest way in this environment is a small loop that calls [System.Windows.Forms.Application]::DoEvents()
            # or just let the job run and have it call back if possible.
            # Callback is safer:
            
            Start-ThreadJob -ArgumentList $job, $window, $OnCompleted, $SetBusy -ScriptBlock {
                param($j, $w, $oc, $sb)
                $res = $j | Wait-Job | Receive-Job
                $w.Dispatcher.Invoke([action]{
                    & $oc $res
                    $sb.Invoke($false)
                })
            }
        }

        # --- GOVERNANCE HANDLERS ---
        $btnGetIntuneDevices.Add_Click({
            $search = $txtIntuneSearch.Text
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-IntuneDevice.ps1") -Raw
            Invoke-AsyncAction -Args @{f=$funcDef; s=$search} -ScriptBlock {
                Invoke-Expression $f
                Get-IntuneDevice -Search $s
            } -OnCompleted {
                param($data)
                $lvIntuneDevices.Items.Clear()
                $data | ForEach-Object { $lvIntuneDevices.Items.Add($_) }
            }
        })

        $btnGetAzureSummary.Add_Click({
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-AzureResourceSummary.ps1") -Raw
            Invoke-AsyncAction -Args @{f=$funcDef} -ScriptBlock {
                Invoke-Expression $f
                Get-AzureResourceSummary
            } -OnCompleted {
                param($data)
                $lvAzureResources.Items.Clear()
                $data | ForEach-Object { $lvAzureResources.Items.Add($_) }
            }
        })

        # --- IDENTITY HANDLERS (LOCAL) ---
        $btnGetLocalUsers.Add_Click({
            $comp = $txtComputerName.Text
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-ComputerLocalUser.ps1") -Raw
            Invoke-AsyncAction -Args @{t=$comp; f=$funcDef} -ScriptBlock {
                Invoke-Expression $f
                Get-ComputerLocalUser -ComputerName $t
            } -OnCompleted {
                param($data)
                $lvLocalAccounts.Items.Clear()
                $data | ForEach-Object { $lvLocalAccounts.Items.Add($_) }
            }
        })

        $btnGetLocalGroups.Add_Click({
            $comp = $txtComputerName.Text
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-ComputerLocalGroup.ps1") -Raw
            Invoke-AsyncAction -Args @{t=$comp; f=$funcDef} -ScriptBlock {
                Invoke-Expression $f
                Get-ComputerLocalGroup -ComputerName $t
            } -OnCompleted {
                param($data)
                $lvLocalAccounts.Items.Clear()
                $data | ForEach-Object { $lvLocalAccounts.Items.Add($_) }
            }
        })

        # --- IDENTITY HANDLERS (ENTRA) ---
        $btnGetEntraUsers.Add_Click({
            $search = $txtEntraSearch.Text
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-EntraIdentity.ps1") -Raw
            Invoke-AsyncAction -Args @{f=$funcDef; s=$search} -ScriptBlock {
                Invoke-Expression $f
                Get-EntraIdentity -Type "User" -Search $s
            } -OnCompleted {
                param($data)
                $lvEntraIdentity.Items.Clear()
                $data | ForEach-Object { $lvEntraIdentity.Items.Add($_) }
            }
        })

        $btnGetEntraGroups.Add_Click({
            $search = $txtEntraSearch.Text
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-EntraIdentity.ps1") -Raw
            Invoke-AsyncAction -Args @{f=$funcDef; s=$search} -ScriptBlock {
                Invoke-Expression $f
                Get-EntraIdentity -Type "Group" -Search $s
            } -OnCompleted {
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
            $comp = $txtComputerName.Text
            Invoke-AsyncAction -Args @{t=$comp} -ScriptBlock {
                if (Test-Connection $t -Count 1 -Quiet) { "[OK] $t online" } else { "[!] $t offline" }
            } -OnCompleted {
                param($res) $AppendOutput.Invoke($res)
            }
        })

        $btnUptime.Add_Click({
            $comp = $txtComputerName.Text
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-ComputerUptime.ps1") -Raw
            Invoke-AsyncAction -Args @{t=$comp; f=$funcDef} -ScriptBlock {
                Invoke-Expression $f
                Get-ComputerUptime -ComputerName $t
            } -OnCompleted {
                param($res) $AppendOutput.Invoke("[UPTIME] $res")
            }
        })

        $btnEnableRdp.Add_Click({
            $comp = $txtComputerName.Text
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Set-ComputerRDP.ps1") -Raw
            Invoke-AsyncAction -Args @{t=$comp; f=$funcDef} -ScriptBlock {
                Invoke-Expression $f
                Set-ComputerRDP -ComputerName $t -Enabled $true
            } -OnCompleted {
                param($res) $AppendOutput.Invoke("[RDP] $res")
            }
        })

        $btnDisableRdp.Add_Click({
            $comp = $txtComputerName.Text
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Set-ComputerRDP.ps1") -Raw
            Invoke-AsyncAction -Args @{t=$comp; f=$funcDef} -ScriptBlock {
                Invoke-Expression $f
                Set-ComputerRDP -ComputerName $t -Enabled $false
            } -OnCompleted {
                param($res) $AppendOutput.Invoke("[RDP] $res")
            }
        })

        # --- SERVICE HANDLERS ---
        $btnGetServices.Add_Click({
            $comp = $txtComputerName.Text
            $search = $txtServiceSearch.Text
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-ComputerService.ps1") -Raw
            Invoke-AsyncAction -Args @{t=$comp; f=$funcDef; s=$search} -ScriptBlock {
                Invoke-Expression $f
                Get-ComputerService -ComputerName $t -Name $s
            } -OnCompleted {
                param($data)
                $lvServices.Items.Clear()
                $data | ForEach-Object { $lvServices.Items.Add($_) }
            }
        })

        $btnGetStoppedAuto.Add_Click({
            $comp = $txtComputerName.Text
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-ComputerService.ps1") -Raw
            Invoke-AsyncAction -Args @{t=$comp; f=$funcDef} -ScriptBlock {
                Invoke-Expression $f
                Get-ComputerService -ComputerName $t -OnlyAutoStopped
            } -OnCompleted {
                param($data)
                $lvServices.Items.Clear()
                $data | ForEach-Object { $lvServices.Items.Add($_) }
            }
        })

        # --- SOFTWARE HANDLERS ---
        $btnGetSoftware.Add_Click({
            $comp = $txtComputerName.Text
            $search = $txtSoftwareSearch.Text
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-ComputerSoftware.ps1") -Raw
            Invoke-AsyncAction -Args @{t=$comp; f=$funcDef; s=$search} -ScriptBlock {
                Invoke-Expression $f
                Get-ComputerSoftware -ComputerName $t -Search $s
            } -OnCompleted {
                param($data)
                $lvSoftware.Items.Clear()
                $data | ForEach-Object { $lvSoftware.Items.Add($_) }
            }
        })

        # --- HARDWARE HANDLERS ---
        $btnGetHardware.Add_Click({
            $comp = $txtComputerName.Text
            $hwFunc = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-ComputerHardware.ps1") -Raw
            $moboFunc = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-ComputerMotherboard.ps1") -Raw
            
            Invoke-AsyncAction -Args @{t=$comp; f1=$hwFunc; f2=$moboFunc} -ScriptBlock {
                Invoke-Expression $f1
                Invoke-Expression $f2
                $hw = Get-ComputerHardware -ComputerName $t
                $mobo = Get-ComputerMotherboard -ComputerName $t
                return @{hw=$hw; mobo=$mobo}
            } -OnCompleted {
                param($data)
                if ($data.hw) {
                    $hw = $data.hw
                    $txtHwModel.Text = "$($hw.Manufacturer) $($hw.Model)"
                    $txtHwSerial.Text = $hw.SerialNumber
                    $txtHwCpu.Text = $hw.CPU
                    $txtHwRam.Text = "$($hw.RAM_GB) GB"
                    $txtHwOs.Text = $hw.OS
                    
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
            $comp = $txtComputerName.Text
            $onlyIP = $chkOnlyIPEnabled.IsChecked
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-ComputerNetwork.ps1") -Raw
            Invoke-AsyncAction -Args @{t=$comp; f=$funcDef; o=$onlyIP} -ScriptBlock {
                Invoke-Expression $f
                Get-ComputerNetwork -ComputerName $t -OnlyIPEnabled $o
            } -OnCompleted {
                param($data)
                $lvNetwork.Items.Clear()
                $data | ForEach-Object { $lvNetwork.Items.Add($_) }
            }
        })

        # --- REGISTRY HANDLERS ---
        $btnRegRead.Add_Click({
            $comp = $txtComputerName.Text
            $hive = $cbRegHive.Text
            $path = $txtRegPath.Text
            $val = $txtRegValueName.Text
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Invoke-ComputerRegistry.ps1") -Raw
            Invoke-AsyncAction -Args @{t=$comp; f=$funcDef; h=$hive; p=$path; v=$val} -ScriptBlock {
                Invoke-Expression $f
                Invoke-ComputerRegistry -Action "Get" -ComputerName $t -Hive $h -KeyPath $p -ValueName $v
            } -OnCompleted {
                param($res) $txtRegResult.Text = if ($res -ne $null) { "Value: $res" } else { "Value not found or error." }
            }
        })

        $btnRegWrite.Add_Click({
            $comp = $txtComputerName.Text
            $hive = $cbRegHive.Text
            $path = $txtRegPath.Text
            $val = $txtRegValueName.Text
            $data = $txtRegValueData.Text
            $type = $cbRegType.Text
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Invoke-ComputerRegistry.ps1") -Raw
            Invoke-AsyncAction -Args @{t=$comp; f=$funcDef; h=$hive; p=$path; v=$val; d=$data; ty=$type} -ScriptBlock {
                Invoke-Expression $f
                Invoke-ComputerRegistry -Action "Set" -ComputerName $t -Hive $h -KeyPath $p -ValueName $v -Value $d -ValueType $ty
            } -OnCompleted {
                param($res) $txtRegResult.Text = if ($res) { "Success: Value written." } else { "Error: Failed to write value." }
            }
        })

        $btnRegDelete.Add_Click({
            $comp = $txtComputerName.Text
            $hive = $cbRegHive.Text
            $path = $txtRegPath.Text
            $val = $txtRegValueName.Text
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Invoke-ComputerRegistry.ps1") -Raw
            Invoke-AsyncAction -Args @{t=$comp; f=$funcDef; h=$hive; p=$path; v=$val} -ScriptBlock {
                Invoke-Expression $f
                Invoke-ComputerRegistry -Action "Remove" -ComputerName $t -Hive $h -KeyPath $p -ValueName $v
            } -OnCompleted {
                param($res) $txtRegResult.Text = if ($res) { "Success: Item removed." } else { "Error: Failed to remove item." }
            }
        })

        # --- CLOUD AUTH HANDLER ---
        $btnCloudLogin.Add_Click({
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Connect-ModernCloud.ps1") -Raw
            Invoke-AsyncAction -Args @{f=$funcDef} -ScriptBlock {
                Invoke-Expression $f
                Connect-ModernCloud -Interactive
            } -OnCompleted {
                param($res)
                $lblCloudStatus.Text = $res
                $lblCloudStatus.Foreground = if ($res -match "OK") { [System.Windows.Media.Brushes]::Green } else { [System.Windows.Media.Brushes]::Red }
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