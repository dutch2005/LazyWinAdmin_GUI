<#
.SYNOPSIS
    Automates the creation of a Hyper-V Virtual Machine for testing LazyWinAdmin.
.DESCRIPTION
    This script prompts you to select a Windows ISO file, then automatically 
    creates a Generation 2 Hyper-V VM with 4GB RAM, 2 CPU Cores, and a 60GB Drive.
    It attaches the ISO and starts the VM so you can install Windows.
.NOTES
    Requires running as Administrator to interact with Hyper-V.
#>
[CmdletBinding()]
param (
    [string]$VMName = "LazyWinAdmin-TestVM",
    [long]$MemoryStartupBytes = 4GB,
    [long]$VHDSizeBytes = 60GB
)

# 1. Require Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges to create a Hyper-V Virtual Machine."
    Write-Host "Please restart PowerShell as Administrator and run this script again." -ForegroundColor Red
    return
}

# 2. Prompt for Windows ISO
Add-Type -AssemblyName System.Windows.Forms
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.Title = "Select your Windows 10/11 or Server ISO file"
$OpenFileDialog.Filter = "ISO Files (*.iso)|*.iso|All Files (*.*)|*.*"
$OpenFileDialog.ShowHelp = $true

Write-Host "Waiting for you to select a Windows ISO file from the pop-up window..." -ForegroundColor Cyan
if ($OpenFileDialog.ShowDialog() -ne 'OK') {
    Write-Warning "No ISO selected. Aborting VM creation."
    return
}
$IsoPath = $OpenFileDialog.FileName
Write-Host "Selected ISO: $IsoPath" -ForegroundColor Green

# 3. Prevent duplicate VM names
if (Get-VM -Name $VMName -ErrorAction SilentlyContinue) {
    Write-Warning "A Virtual Machine named '$VMName' already exists!"
    return
}

# 4. Setup paths
$VmHost = Get-VMHost
$VhdPath = Join-Path $VmHost.VirtualHardDiskPath "$VMName.vhdx"

# 5. Create Virtual Machine
Write-Host "Creating Virtual Machine '$VMName' (Gen 2, $MemoryStartupBytes RAM, 60GB Disk)..." -ForegroundColor Cyan
New-VM -Name $VMName -MemoryStartupBytes $MemoryStartupBytes -NewVHDPath $VhdPath -NewVHDSizeBytes $VHDSizeBytes -Generation 2 -SwitchName "Default Switch" | Out-Null

# 6. Configure CPU and Secure Boot
Set-VM -Name $VMName -ProcessorCount 2
Set-VMFirmware -VMName $VMName -EnableSecureBoot On -Template "MicrosoftWindows"

# 7. Add DVD Drive and mount ISO
Add-VMDvdDrive -VMName $VMName -Path $IsoPath | Out-Null
$dvd = Get-VMDvdDrive -VMName $VMName

# 8. Set boot order to DVD first
Set-VMFirmware -VMName $VMName -FirstBootDevice $dvd

# 9. Start the VM
Write-Host "Starting $VMName..." -ForegroundColor Green
Start-VM -Name $VMName

# 10. Final Instructions
Write-Host ""
Write-Host "=========================================================" -ForegroundColor Magenta
Write-Host "SUCCESS! The Virtual Machine is now running." -ForegroundColor Green
Write-Host "1. Open Hyper-V Manager."
Write-Host "2. Double-click '$VMName' to open the console."
Write-Host "3. Press any key quickly to boot from the DVD and install Windows."
Write-Host ""
Write-Host "CRITICAL NEXT STEP AFTER INSTALLATION:" -ForegroundColor Red
Write-Host "Once Windows is installed and you reach the desktop, open PowerShell"
Write-Host "as Administrator INSIDE the VM and run this command:"
Write-Host "    Enable-PSRemoting -Force" -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Magenta
