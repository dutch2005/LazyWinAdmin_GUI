# Strict mode according to powershell-windows skill
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# Load Classes
$classFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot "Classes") -Filter "*.ps1"
foreach ($file in $classFiles) {
    . $file.FullName
}

# Load Private Functions
$privateFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot "Private") -Filter "*.ps1"
foreach ($file in $privateFiles) {
    . $file.FullName
}

# Load Public Functions
$publicFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot "Public") -Filter "*.ps1"
foreach ($file in $publicFiles) {
    . $file.FullName
}

# Load UI Functions
$uiFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot "UI") -Filter "*.ps1"
foreach ($file in $uiFiles) {
    . $file.FullName
}

Export-ModuleMember -Function Start-LazyWinAdmin