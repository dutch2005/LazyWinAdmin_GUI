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

        # Find Controls
        $txtComputerName = $window.FindName("txtComputerName")
        $btnPing = $window.FindName("btnPing")
        $btnUptime = $window.FindName("btnUptime")
        $btnCheckPort = $window.FindName("btnCheckPort")
        $txtOutput = $window.FindName("txtOutput")
        $lblStatus = $window.FindName("lblStatus")
        $pbBusy = $window.FindName("pbBusy")

        # Default Value
        $txtComputerName.Text = $env:COMPUTERNAME

        # Helper function to append text to output
        $AppendOutput = {
            param($text)
            $txtOutput.Dispatcher.Invoke([action]{
                $txtOutput.AppendText("$text`n")
                $txtOutput.ScrollToEnd()
            })
        }

        $SetBusy = {
            param([bool]$isBusy)
            $window.Dispatcher.Invoke([action]{
                $pbBusy.IsIndeterminate = $isBusy
                $btnPing.IsEnabled = -not $isBusy
                $btnUptime.IsEnabled = -not $isBusy
                $btnCheckPort.IsEnabled = -not $isBusy
                $lblStatus.Text = if ($isBusy) { "Working..." } else { "Ready" }
            })
        }

        # Event Handlers
        $btnPing.Add_Click({
            $comp = $txtComputerName.Text
            if ([string]::IsNullOrWhiteSpace($comp)) { return }

            $SetBusy.Invoke($true)
            $AppendOutput.Invoke("Pinging $comp ...")

            # Example of Runspace/ThreadJob to prevent UI freeze
            $job = Start-ThreadJob -RunspacePool $state.RunspacePool -ArgumentList $comp -ScriptBlock {
                param($target)
                if (Test-Connection -ComputerName $target -Count 1 -Quiet) {
                    return "[OK] $target replied to ping."
                }
                else {
                    return "[!] $target did not reply to ping."
                }
            }

            # Register a timer to check job completion
            $timer = New-Object System.Windows.Threading.DispatcherTimer
            $timer.Interval = [TimeSpan]::FromMilliseconds(100)
            $timer.Add_Tick({
                if ($job.State -ne 'Running') {
                    $timer.Stop()
                    $result = Receive-Job -Job $job
                    $AppendOutput.Invoke($result)
                    $SetBusy.Invoke($false)
                    Remove-Job -Job $job
                }
            })
            $timer.Start()
        })

        $btnUptime.Add_Click({
            $comp = $txtComputerName.Text
            if ([string]::IsNullOrWhiteSpace($comp)) { return }

            $SetBusy.Invoke($true)
            $AppendOutput.Invoke("Getting uptime for $comp ...")

            # Pass the function definition into the thread job
            $getUptimeDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Get-ComputerUptime.ps1") -Raw

            $job = Start-ThreadJob -RunspacePool $state.RunspacePool -ArgumentList $comp, $getUptimeDef -ScriptBlock {
                param($target, $funcDef)
                Invoke-Expression $funcDef
                $result = Get-ComputerUptime -ComputerName $target
                return "[INFO] Uptime for $target : $result"
            }

            $timer = New-Object System.Windows.Threading.DispatcherTimer
            $timer.Interval = [TimeSpan]::FromMilliseconds(100)
            $timer.Add_Tick({
                if ($job.State -ne 'Running') {
                    $timer.Stop()
                    $result = Receive-Job -Job $job
                    $AppendOutput.Invoke($result)
                    $SetBusy.Invoke($false)
                    Remove-Job -Job $job
                }
            })
            $timer.Start()
        })

        $btnCheckPort.Add_Click({
            $comp = $txtComputerName.Text
            if ([string]::IsNullOrWhiteSpace($comp)) { return }

            $SetBusy.Invoke($true)
            $AppendOutput.Invoke("Checking port 80 on $comp ...")

            $checkPortDef = Get-Content (Join-Path $PSScriptRoot "..\Private\Test-ComputerPort.ps1") -Raw

            $job = Start-ThreadJob -RunspacePool $state.RunspacePool -ArgumentList $comp, $checkPortDef -ScriptBlock {
                param($target, $funcDef)
                Invoke-Expression $funcDef
                $result = Test-ComputerPort -ComputerName $target -Port 80
                return "[INFO] Port 80 on $target : $result"
            }

            $timer = New-Object System.Windows.Threading.DispatcherTimer
            $timer.Interval = [TimeSpan]::FromMilliseconds(100)
            $timer.Add_Tick({
                if ($job.State -ne 'Running') {
                    $timer.Stop()
                    $result = Receive-Job -Job $job
                    $AppendOutput.Invoke($result)
                    $SetBusy.Invoke($false)
                    Remove-Job -Job $job
                }
            })
            $timer.Start()
        })

        # Show the GUI
        $window.ShowDialog() | Out-Null
    }
    catch {
        Write-Warning "Failed to start LazyWinAdmin: $_"
    }
    finally {
        $state.Dispose()
    }
}