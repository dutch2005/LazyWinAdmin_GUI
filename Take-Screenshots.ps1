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
    [int]    $ClickDelayMs = 800,
    # How long (ms) to poll for the window to appear before giving up
    [int]    $WindowWaitMs = 30000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ──────────────────────────────────────────────────────────────────────────────
# 1.  Win32 helpers — FindWindow, GetWindowRect, SetForegroundWindow, SendMessage
# ──────────────────────────────────────────────────────────────────────────────
Add-Type -TypeDefinition @'
using System;
using System.Drawing;
using System.Runtime.InteropServices;

public static class WinCapture {

    [DllImport("user32.dll", SetLastError=true)]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll", SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr child,
                                              string className, string windowName);

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left, Top, Right, Bottom;
        public int Width  { get { return Right - Left; } }
        public int Height { get { return Bottom - Top; } }
    }

    // SW_RESTORE = 9, SW_MAXIMIZE = 3
    public const int SW_RESTORE  = 9;
    public const int SW_MAXIMIZE = 3;

    public static Bitmap CaptureWindow(IntPtr hWnd) {
        RECT rc;
        GetWindowRect(hWnd, out rc);
        var bmp = new Bitmap(rc.Width, rc.Height, System.Drawing.Imaging.PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(bmp)) {
            g.CopyFromScreen(rc.Left, rc.Top, 0, 0,
                             new Size(rc.Width, rc.Height),
                             CopyPixelOperation.SourceCopy);
        }
        return bmp;
    }
}
'@ -ReferencedAssemblies 'System.Drawing', 'System.Drawing.Common' -ErrorAction Stop

Add-Type -AssemblyName System.Drawing

# ──────────────────────────────────────────────────────────────────────────────
# 2.  Helper — click a point relative to the window (for tab switching)
# ──────────────────────────────────────────────────────────────────────────────
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class MouseHelper {
    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);

    [DllImport("user32.dll")]
    public static extern void mouse_event(int dwFlags, int dx, int dy,
                                           int cButtons, int dwExtraInfo);

    public const int MOUSEEVENTF_LEFTDOWN = 0x02;
    public const int MOUSEEVENTF_LEFTUP   = 0x04;

    public static void Click(int x, int y) {
        SetCursorPos(x, y);
        mouse_event(MOUSEEVENTF_LEFTDOWN, x, y, 0, 0);
        System.Threading.Thread.Sleep(50);
        mouse_event(MOUSEEVENTF_LEFTUP,   x, y, 0, 0);
    }
}
'@

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

    # WPF windows use HwndSource — enumerate all visible top-level windows
    # and look for the title
    $hWnd = [WinCapture]::FindWindow($null, 'LazyWinAdmin')
    if ($hWnd -ne [IntPtr]::Zero) { break }
}

if ($hWnd -eq [IntPtr]::Zero) {
    Write-Warning "Window 'LazyWinAdmin' not found after ${WindowWaitMs}ms. Aborting."
    $guiProcess | Stop-Process -Force -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "[+] Window found (hWnd=$hWnd)"

# Restore + bring to front
[WinCapture]::ShowWindow($hWnd, [WinCapture]::SW_RESTORE) | Out-Null
Start-Sleep -Milliseconds 300
[WinCapture]::SetForegroundWindow($hWnd) | Out-Null
Start-Sleep -Milliseconds 600   # let the window fully paint

# ──────────────────────────────────────────────────────────────────────────────
# 5.  Helper — save a screenshot
# ──────────────────────────────────────────────────────────────────────────────
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }

function Save-Screenshot {
    param([string]$Name)
    $path = Join-Path $OutputFolder "lwa-v1.3-$Name.png"
    $bmp  = [WinCapture]::CaptureWindow($hWnd)
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "[+] Saved: $path"
}

# ──────────────────────────────────────────────────────────────────────────────
# 6.  Capture the default (first tab) view
# ──────────────────────────────────────────────────────────────────────────────
Save-Screenshot -Name 'main'
Start-Sleep -Milliseconds 300

# ──────────────────────────────────────────────────────────────────────────────
# 7.  Click through the tabs using approximate pixel offsets from the window top
#
#     The WPF TabControl renders tab headers along the top. With the default
#     window size, the tabs are roughly at Y = window.Top + 82 px.
#     X offsets below are approximate centres of each tab header.
#     Adjust if your DPI / scaling differs.
# ──────────────────────────────────────────────────────────────────────────────
$tabDefs = [ordered]@{
    'system-network'  = 70
    'services'        = 175
    'software'        = 270
    'hardware'        = 360
    'network'         = 445
    'identity'        = 525
    'compliance'      = 620
    'exchange'        = 710
    'governance'      = 800
    'registry'        = 890
    'cloud-auth'      = 970
}

[WinCapture+RECT] $rc = [WinCapture+RECT]::new()
[WinCapture]::GetWindowRect($hWnd, [ref]$rc) | Out-Null

foreach ($tab in $tabDefs.GetEnumerator()) {
    $clickX = $rc.Left + $tab.Value
    $clickY = $rc.Top  + 82          # approximate tab-strip Y

    [WinCapture]::SetForegroundWindow($hWnd) | Out-Null
    [MouseHelper]::Click($clickX, $clickY)
    Start-Sleep -Milliseconds $ClickDelayMs

    Save-Screenshot -Name $tab.Key
}

# ──────────────────────────────────────────────────────────────────────────────
# 8.  Done — leave the window open so the user can inspect it;
#     they can close it manually.
# ──────────────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[✓] Screenshots saved to: $OutputFolder"
Write-Host "    Close the LazyWinAdmin window when done."
