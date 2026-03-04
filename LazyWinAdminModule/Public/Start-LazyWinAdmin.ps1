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
        $txtOutput = $window.FindName("txtOutput")
        
        $btnGetServices = $window.FindName("btnGetServices")
        $lvServices = $window.FindName("lvServices")
        $txtServiceSearch = $window.FindName("txtServiceSearch")

        # Identity Controls
        $btnGetLocalUsers = $window.FindName("btnGetLocalUsers")
        $btnGetLocalGroups = $window.FindName("btnGetLocalGroups")
        $lvLocalAccounts = $window.FindName("lvLocalAccounts")
        $btnGetEntraUsers = $window.FindName("btnGetEntraUsers")
        $btnGetEntraGroups = $window.FindName("btnGetEntraGroups")
        $lvEntraIdentity = $window.FindName("lvEntraIdentity")
        $txtEntraSearch = $window.FindName("txtEntraSearch")

        $btnRegRead = $window.FindName("btnRegRead")
        $cbRegHive = $window.FindName("cbRegHive")
        $txtRegValueName = $window.FindName("txtRegValueName")
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

        # --- IDENTITY HANDLERS (LOCAL) ---
        $btnGetLocalUsers.Add_Click({
            $comp = $txtComputerName.Text
            $SetBusy.Invoke($true)
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-ComputerLocalUser.ps1") -Raw
            Start-ThreadJob -RunspacePool $state.RunspacePool -ArgumentList $comp, $funcDef -ScriptBlock {
                param($t, $f) ; Invoke-Expression $f
                return Get-ComputerLocalUser -ComputerName $t
            } | Wait-Job | Receive-Job | ForEach-Object {
                $window.Dispatcher.Invoke([action]{
                    $lvLocalAccounts.Items.Clear()
                    $_ | ForEach-Object { $lvLocalAccounts.Items.Add($_) }
                })
            }
            $SetBusy.Invoke($false)
        })

        $btnGetLocalGroups.Add_Click({
            $comp = $txtComputerName.Text
            $SetBusy.Invoke($true)
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-ComputerLocalGroup.ps1") -Raw
            Start-ThreadJob -RunspacePool $state.RunspacePool -ArgumentList $comp, $funcDef -ScriptBlock {
                param($t, $f) ; Invoke-Expression $f
                return Get-ComputerLocalGroup -ComputerName $t
            } | Wait-Job | Receive-Job | ForEach-Object {
                $window.Dispatcher.Invoke([action]{
                    $lvLocalAccounts.Items.Clear()
                    $_ | ForEach-Object { $lvLocalAccounts.Items.Add($_) }
                })
            }
            $SetBusy.Invoke($false)
        })

        # --- IDENTITY HANDLERS (ENTRA) ---
        $btnGetEntraUsers.Add_Click({
            $SetBusy.Invoke($true)
            $search = $txtEntraSearch.Text
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-EntraIdentity.ps1") -Raw
            Start-ThreadJob -RunspacePool $state.RunspacePool -ArgumentList $funcDef, $search -ScriptBlock {
                param($f, $s) ; Invoke-Expression $f
                return Get-EntraIdentity -Type "User" -Search $s
            } | Wait-Job | Receive-Job | ForEach-Object {
                $window.Dispatcher.Invoke([action]{
                    $lvEntraIdentity.Items.Clear()
                    $_ | ForEach-Object { $lvEntraIdentity.Items.Add($_) }
                })
            }
            $SetBusy.Invoke($false)
        })

        $btnGetEntraGroups.Add_Click({
            $SetBusy.Invoke($true)
            $search = $txtEntraSearch.Text
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-EntraIdentity.ps1") -Raw
            Start-ThreadJob -RunspacePool $state.RunspacePool -ArgumentList $funcDef, $search -ScriptBlock {
                param($f, $s) ; Invoke-Expression $f
                return Get-EntraIdentity -Type "Group" -Search $s
            } | Wait-Job | Receive-Job | ForEach-Object {
                $window.Dispatcher.Invoke([action]{
                    $lvEntraIdentity.Items.Clear()
                    $_ | ForEach-Object { 
                        # Remap Description to UserPrincipalName field for display consistency in this specific UI
                        $item = $_
                        if ($item.Description) { $item.UserPrincipalName = $item.Description }
                        $lvEntraIdentity.Items.Add($item) 
                    }
                })
            }
            $SetBusy.Invoke($false)
        })

        # --- SYSTEM HANDLERS ---
        $btnPing.Add_Click({
            $comp = $txtComputerName.Text
            $SetBusy.Invoke($true)
            Start-ThreadJob -RunspacePool $state.RunspacePool -ArgumentList $comp -ScriptBlock {
                param($t) ; if (Test-Connection $t -Count 1 -Quiet) { return "[OK] $t online" } else { return "[!] $t offline" }
            } | Wait-Job | Receive-Job | ForEach-Object { $AppendOutput.Invoke($_) }
            $SetBusy.Invoke($false)
        })

        $btnUptime.Add_Click({
            $comp = $txtComputerName.Text
            $SetBusy.Invoke($true)
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-ComputerUptime.ps1") -Raw
            Start-ThreadJob -RunspacePool $state.RunspacePool -ArgumentList $comp, $funcDef -ScriptBlock {
                param($t, $f) ; Invoke-Expression $f ; return Get-ComputerUptime -ComputerName $t
            } | Wait-Job | Receive-Job | ForEach-Object { $AppendOutput.Invoke("[UPTIME] $_") }
            $SetBusy.Invoke($false)
        })

        # --- SERVICE HANDLERS ---
        $btnGetServices.Add_Click({
            $comp = $txtComputerName.Text
            $SetBusy.Invoke($true)
            $search = $txtServiceSearch.Text
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-ComputerService.ps1") -Raw
            Start-ThreadJob -RunspacePool $state.RunspacePool -ArgumentList $comp, $funcDef, $search -ScriptBlock {
                param($t, $f, $s) ; Invoke-Expression $f ; return Get-ComputerService -ComputerName $t -Name $s
            } | Wait-Job | Receive-Job | ForEach-Object {
                $window.Dispatcher.Invoke([action]{
                    $lvServices.Items.Clear()
                    $_ | ForEach-Object { $lvServices.Items.Add($_) }
                })
            }
            $SetBusy.Invoke($false)
        })

        # --- REGISTRY HANDLERS ---
        $btnRegRead.Add_Click({
            $comp = $txtComputerName.Text
            $hive = $cbRegHive.Text
            $path = $txtRegPath.Text
            $val = $txtRegValueName.Text
            $SetBusy.Invoke($true)
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-ComputerRegistryValue.ps1") -Raw
            Start-ThreadJob -RunspacePool $state.RunspacePool -ArgumentList $comp, $funcDef, $hive, $path, $val -ScriptBlock {
                param($t, $f, $h, $p, $v) ; Invoke-Expression $f ; return Get-ComputerRegistryValue -ComputerName $t -Hive $h -KeyPath $p -ValueName $v
            } | Wait-Job | Receive-Job | ForEach-Object {
                $window.Dispatcher.Invoke([action]{ $txtRegResult.Text = if ($_) { "Value: $_" } else { "Value not found." } })
            }
            $SetBusy.Invoke($false)
        })

        # --- CLOUD AUTH HANDLER ---
        $btnCloudLogin.Add_Click({
            $SetBusy.Invoke($true)
            $funcDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Connect-ModernCloud.ps1") -Raw
            Start-ThreadJob -RunspacePool $state.RunspacePool -ArgumentList $funcDef -ScriptBlock {
                param($f) ; Invoke-Expression $f ; return Connect-ModernCloud -Interactive
            } | Wait-Job | Receive-Job | ForEach-Object {
                $window.Dispatcher.Invoke([action]{
                    $lblCloudStatus.Text = $_
                    $lblCloudStatus.Foreground = if ($_ -match "OK") { [System.Windows.Media.Brushes]::Green } else { [System.Windows.Media.Brushes]::Red }
                })
            }
            $SetBusy.Invoke($false)
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