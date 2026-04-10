<#
.SYNOPSIS
    Launches the LazyWinAdmin v1.3.0 WPF GUI and captures screenshots of each tab.

.DESCRIPTION
    Starts the GUI in a separate PowerShell process, waits for the window to appear,
    then uses the Windows GDI API to capture the client area and save PNG files to
    the Media\ folder. Run this script from the repository root.

    Prerequisites: all required modules must already be installed (see README).

.OUTPUTS
    Media\lwa-v1.3-<tab>.png  — one screenshot per captured tab

.EXAMPLE
    pwsh -NoProfile -File .\Take-Screenshots.ps1
#>

#Requires -Version 7.4

[CmdletBinding()]
param(
    [string] $OutputFolder = (Join-Path $PSScriptRoot 'Media'),
    # How long (ms) to wait after sending a click before capturing
    [int]    $ClickDelayMs = 1000,
    # How long (ms) to poll for the window to appear before giving up
    [int]    $WindowWaitMs = 45000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ──────────────────────────────────────────────────────────────────────────────
# 1.  Win32 window helpers (no System.Drawing references in C# — use PS instead)
# ──────────────────────────────────────────────────────────────────────────────
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class WinApi {

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetWindowRect(IntPtr hWnd, ref RECT lpRect);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    // Move and resize in one call — SWP_NOZORDER = 0x0004, SWP_SHOWWINDOW = 0x0040
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter,
                                           int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);

    [DllImport("user32.dll")]
    public static extern void mouse_event(uint dwFlags, int dx, int dy,
                                          uint cButtons, UIntPtr dwExtraInfo);

    public static readonly IntPtr HWND_TOP = IntPtr.Zero;
    public const uint SWP_NOZORDER   = 0x0004;
    public const uint SWP_SHOWWINDOW = 0x0040;

    public const int SW_RESTORE  = 9;
    public const int SW_MAXIMIZE = 3;
    public const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
    public const uint MOUSEEVENTF_LEFTUP   = 0x0004;

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left, Top, Right, Bottom;
        public int Width  { get { return Right - Left; } }
        public int Height { get { return Bottom - Top; } }
    }

    public static void Click(int x, int y) {
        SetCursorPos(x, y);
        System.Threading.Thread.Sleep(80);
        mouse_event(MOUSEEVENTF_LEFTDOWN, x, y, 0, UIntPtr.Zero);
        System.Threading.Thread.Sleep(80);
        mouse_event(MOUSEEVENTF_LEFTUP,   x, y, 0, UIntPtr.Zero);
    }
}
'@

# ──────────────────────────────────────────────────────────────────────────────
# 2.  Screenshot via PowerShell + System.Drawing (avoids the GdiPlus CS0012
#     compile error that occurs when System.Drawing is referenced from Add-Type)
# ──────────────────────────────────────────────────────────────────────────────
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms   # needed for Clipboard

# ──────────────────────────────────────────────────────────────────────────────
# 3.  Launch the GUI in a separate process
# ──────────────────────────────────────────────────────────────────────────────
$modulePath = Join-Path $PSScriptRoot 'LazyWinAdminModule\LazyWinAdminModule.psd1'
if (-not (Test-Path $modulePath)) {
    throw "Module not found at '$modulePath'. Run this script from the repository root."
}

Write-Host "[*] Launching LazyWinAdmin GUI..."
$guiProcess = Start-Process pwsh -ArgumentList @(
    '-NoProfile',
    '-WindowStyle', 'Normal',
    '-Command', "Import-Module '$modulePath' -Force; Start-LazyWinAdmin"
) -PassThru

# ──────────────────────────────────────────────────────────────────────────────
# 4.  Wait for the WPF window to appear
# ──────────────────────────────────────────────────────────────────────────────
Write-Host "[*] Waiting for window (up to $($WindowWaitMs / 1000)s)..."
$elapsed = 0
$hWnd    = [IntPtr]::Zero
while ($elapsed -lt $WindowWaitMs) {
    Start-Sleep -Milliseconds 500
    $elapsed += 500

    # WPF windows in .NET 6+ are not reliably found by FindWindow.
    # Get-Process.MainWindowHandle is the authoritative way to get the HWND.
    $p = Get-Process -Id $guiProcess.Id -ErrorAction SilentlyContinue
    if (-not $p) {
        Write-Warning "GUI process exited unexpectedly after ${elapsed}ms. Aborting."
        exit 1
    }
    if ($p.MainWindowHandle -ne [IntPtr]::Zero) {
        $hWnd = $p.MainWindowHandle
        break
    }
}

if ($hWnd -eq [IntPtr]::Zero) {
    Write-Warning "LazyWinAdmin window not found after ${WindowWaitMs}ms. Aborting."
    $guiProcess | Stop-Process -Force -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "[+] Window found (hWnd=0x$($hWnd.ToString('X'))) title='$((Get-Process -Id $guiProcess.Id).MainWindowTitle)'"

# Restore, move to a known screen position, then bring to front.
# A fixed origin eliminates any partial-offscreen overlap that would cause
# the capture area to include other applications' pixels in the screenshot.
[WinApi]::ShowWindow($hWnd, [WinApi]::SW_RESTORE) | Out-Null
Start-Sleep -Milliseconds 300
[WinApi]::SetWindowPos($hWnd, [WinApi]::HWND_TOP, 50, 50, 1200, 800,
    ([WinApi]::SWP_NOZORDER -bor [WinApi]::SWP_SHOWWINDOW)) | Out-Null
Start-Sleep -Milliseconds 400
[WinApi]::SetForegroundWindow($hWnd) | Out-Null
Start-Sleep -Milliseconds 800

# ──────────────────────────────────────────────────────────────────────────────
# 5.  Screenshot helper — pure PowerShell using System.Drawing
# ──────────────────────────────────────────────────────────────────────────────
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }

function Save-Screenshot {
    param([string]$Name)

    # Re-read the window rect each time (window may have moved/resized)
    $rc = [WinApi+RECT]::new()
    [WinApi]::GetWindowRect($hWnd, [ref]$rc) | Out-Null

    $w = $rc.Width
    $h = $rc.Height
    if ($w -le 0 -or $h -le 0) {
        Write-Warning "Window rect invalid ($w x $h) — skipping $Name"
        return
    }

    $bmp = [System.Drawing.Bitmap]::new($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    try {
        $g.CopyFromScreen($rc.Left, $rc.Top, 0, 0, [System.Drawing.Size]::new($w, $h),
                          [System.Drawing.CopyPixelOperation]::SourceCopy)
    }
    finally {
        $g.Dispose()
    }

    $path = Join-Path $OutputFolder "lwa-v1.3-$Name.png"
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "[+] Saved: $path  ($w x $h)"
}

# ──────────────────────────────────────────────────────────────────────────────
# 6.  Capture the default (first tab) view
# ──────────────────────────────────────────────────────────────────────────────
Save-Screenshot -Name 'main'
Start-Sleep -Milliseconds 400

# ──────────────────────────────────────────────────────────────────────────────
# 7.  Switch tabs via Windows UI Automation (no pixel coordinates needed).
#
#     UIAutomation finds each TabItem in the WPF window by its header text,
#     then invokes SelectionItemPattern.Select() — reliable across any DPI.
# ──────────────────────────────────────────────────────────────────────────────
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

# Map screenshot filename suffix -> tab header text as it appears in the UI
$tabDefs = [ordered]@{
    'system-network' = 'System & Network'
    'services'       = 'Services'
    'software'       = 'Software Inventory'
    'hardware'       = 'Hardware Inventory'
    'network'        = 'Network'
    'identity'       = 'Identity (Users/Groups)'
    'compliance'     = 'Device Compliance'
    'exchange'       = 'Exchange'
    'governance'     = 'Governance & Compliance'
    'registry'       = 'Registry'
    'cloud-auth'     = 'Cloud Auth'
}

# Get the Automation root element for this window
$windowElement = [System.Windows.Automation.AutomationElement]::FromHandle($hWnd)

# Helper: find a TabItem by its name and select it
function Select-Tab {
    param([string]$TabName)

    $cond = [System.Windows.Automation.PropertyCondition]::new(
        [System.Windows.Automation.AutomationElement]::NameProperty, $TabName)
    $typeCond = [System.Windows.Automation.PropertyCondition]::new(
        [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
        [System.Windows.Automation.ControlType]::TabItem)
    $andCond = [System.Windows.Automation.AndCondition]::new($cond, $typeCond)

    $tabItem = $windowElement.FindFirst(
        [System.Windows.Automation.TreeScope]::Descendants, $andCond)

    if ($null -eq $tabItem) {
        Write-Warning "TabItem '$TabName' not found in UIAutomation tree — skipping."
        return $false
    }

    $selPattern = $tabItem.GetCurrentPattern(
        [System.Windows.Automation.SelectionItemPattern]::Pattern)
    $selPattern.Select()
    return $true
}

foreach ($tab in $tabDefs.GetEnumerator()) {
    [WinApi]::SetForegroundWindow($hWnd) | Out-Null
    $found = Select-Tab -TabName $tab.Value
    Start-Sleep -Milliseconds $ClickDelayMs

    if ($found) {
        Save-Screenshot -Name $tab.Key
    }
}

# ──────────────────────────────────────────────────────────────────────────────
# 8.  Done
# ──────────────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[OK] Screenshots saved to: $OutputFolder"
Write-Host "     Close the LazyWinAdmin window when done."
