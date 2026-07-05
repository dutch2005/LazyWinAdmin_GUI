function Start-LazyWinAdmin {
    <#
    .SYNOPSIS
        Starts the modernized WPF-based LazyWinAdmin GUI.
    .DESCRIPTION
        Thin orchestrator: loads the WPF window, then dot-sources the UI section
        files under UI/Handlers/ INTO this scope. Dot-sourcing is scope-transparent,
        so each section (control lookup, helpers + async engine, per-tab handlers,
        chrome) runs exactly as it did in the former single 1000-line function, but
        each concern now lives in its own small file. New feature tabs add a new
        Register-*.ps1 section here rather than growing this function.
        NOTE: UI/Handlers/*.ps1 are deliberately NOT function definitions and are NOT
        auto-loaded by the .psm1 (which only globs Private/Public/Classes/UI top level).
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseDeclaredVarsMoreThanAssignments', 'PrivatePath',
        Justification = '$PrivatePath is consumed by the dot-sourced UI/Handlers section files (cross-file scope the analyzer cannot follow).')]
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
    $PrivatePath    = (Resolve-Path (Join-Path $PSScriptRoot "..\Private")).Path
    $UiHandlerPath  = (Resolve-Path (Join-Path $PSScriptRoot "..\UI\Handlers")).Path

    try {
        $xamlPath    = Join-Path $PSScriptRoot "..\UI\MainView.xaml"
        $xamlContent = Get-Content -Path $xamlPath -Raw

        $xmlDoc    = [System.Xml.XmlDocument]::new()
        $xmlDoc.LoadXml($xamlContent)
        $xmlReader = [System.Xml.XmlNodeReader]::new($xmlDoc)
        $window    = [System.Windows.Markup.XamlReader]::Load($xmlReader)

        # Control lookup — populates $txt*/$btn*/$lv* locals in this scope.
        . (Join-Path $UiHandlerPath 'Find-Controls.ps1')

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

        # Shared helpers ($AppendOutput, $SetBusy, guards, $AdminHint,
        # $ExportListViewToCsv) + the Invoke-AsyncAction engine.
        . (Join-Path $UiHandlerPath 'Initialize-Helpers.ps1')

        # Per-tab event handler registration (order independent; all reference the
        # helpers/controls above).
        . (Join-Path $UiHandlerPath 'Register-SystemServiceHandlers.ps1')
        . (Join-Path $UiHandlerPath 'Register-InventoryHandlers.ps1')
        . (Join-Path $UiHandlerPath 'Register-IdentityHandlers.ps1')
        . (Join-Path $UiHandlerPath 'Register-GovernanceHandlers.ps1')
        . (Join-Path $UiHandlerPath 'Register-RegistryAdHandlers.ps1')
        . (Join-Path $UiHandlerPath 'Register-ExchangeCloudHandlers.ps1')
        . (Join-Path $UiHandlerPath 'Register-ExportHandlers.ps1')

        # Clipboard context menus + dispatcher/clock timers (runs at load time).
        . (Join-Path $UiHandlerPath 'Initialize-UiChrome.ps1')

        $window.ShowDialog() | Out-Null
    }
    catch {
        Write-Warning "Failed to start LazyWinAdmin: $_"
    }
    finally {
        $state.Dispose()
    }
}
