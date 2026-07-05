#Requires -Version 7.4
<#
.SYNOPSIS
    Runner script for the LazyWinAdmin Pester v5 test suite.

.DESCRIPTION
    1. Ensures Pester v5+ is available (installs if missing).
    2. Runs Integrity.Tests.ps1 and Functions.Tests.ps1 with Detailed output.
    3. Exits with code 1 if any tests fail; 0 on full pass.
    4. Displays a summary at the end.

.EXAMPLE
    pwsh -File Run-Tests.ps1
    pwsh -File Run-Tests.ps1 -Verbose
#>

[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost', '',
    Justification = 'Test runner intentionally uses Write-Host for colored console output.')]
[CmdletBinding()]
param (
    # Override test output verbosity. Defaults to Detailed.
    [ValidateSet('None','Normal','Detailed','Diagnostic')]
    [string]$Output = 'Detailed',

    # Run only the specified test file(s). By default both suites run.
    [ValidateSet('Integrity','Functions','Both')]
    [string]$Suite = 'Both'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ─────────────────────────────────────────────────────────────────────────────
# 1. Ensure Pester v5+ is available
# ─────────────────────────────────────────────────────────────────────────────
Write-Host '=== LazyWinAdmin Test Runner ===' -ForegroundColor Cyan

$pesterModule = Get-Module -Name Pester -ListAvailable |
                Where-Object { $_.Version.Major -ge 5 } |
                Sort-Object Version -Descending |
                Select-Object -First 1

if (-not $pesterModule) {
    Write-Host '[INFO] Pester v5 not found. Attempting to install from PSGallery...' -ForegroundColor Yellow
    try {
        Install-Module -Name Pester -MinimumVersion '5.0.0' -Scope CurrentUser -Force -SkipPublisherCheck
        Write-Host '[INFO] Pester installed successfully.' -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install Pester: $_"
        exit 1
    }
}
else {
    Write-Host "[INFO] Using Pester $($pesterModule.Version)" -ForegroundColor Green
}

# Import the highest available v5+ Pester explicitly to avoid auto-loading v4
Import-Module Pester -MinimumVersion '5.0.0' -Force

# ─────────────────────────────────────────────────────────────────────────────
# 2. Locate test files (dynamically discover all *.Tests.ps1 in Tests dir)
# ─────────────────────────────────────────────────────────────────────────────
$TestsDir     = $PSScriptRoot
$allTestFiles = Get-ChildItem -Path $TestsDir -Filter '*.Tests.ps1' |
                    Select-Object -ExpandProperty FullName

if (-not $allTestFiles) {
    Write-Error "No *.Tests.ps1 files found in: $TestsDir"
    exit 1
}

$testPaths = @(switch ($Suite) {
    'Integrity' { $allTestFiles | Where-Object { $_ -like '*Integrity*' } }
    'Functions' { $allTestFiles | Where-Object { $_ -notlike '*Integrity*' } }
    default     { $allTestFiles }
})

if (-not $testPaths) {
    Write-Error "No test files matched Suite '$Suite' in: $TestsDir"
    exit 1
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. Configure and run Pester
# ─────────────────────────────────────────────────────────────────────────────
$config = New-PesterConfiguration
$config.Run.Path            = $testPaths
$config.Output.Verbosity    = $Output
$config.Run.PassThru        = $true   # capture result object for exit-code logic
$config.TestResult.Enabled  = $false  # disable NUnit XML output by default

Write-Host ''
Write-Host "Running suites: $($testPaths | ForEach-Object { Split-Path $_ -Leaf })" -ForegroundColor Cyan
Write-Host ''

$result = Invoke-Pester -Configuration $config

# ─────────────────────────────────────────────────────────────────────────────
# 4. Summary
# ─────────────────────────────────────────────────────────────────────────────
Write-Host ''
Write-Host '─────────────────────────────────────────────────────────────────────' -ForegroundColor DarkGray
Write-Host '  TEST SUMMARY' -ForegroundColor Cyan
Write-Host '─────────────────────────────────────────────────────────────────────' -ForegroundColor DarkGray

if ($result) {
    $passCount   = $result.PassedCount
    $failCount   = $result.FailedCount
    $skipCount   = $result.SkippedCount
    $totalCount  = $result.TotalCount
    $duration    = $result.Duration

    Write-Host "  Total   : $totalCount"
    Write-Host "  Passed  : $passCount"  -ForegroundColor Green
    if ($failCount -gt 0) {
        Write-Host "  Failed  : $failCount"  -ForegroundColor Red
    }
    else {
        Write-Host "  Failed  : $failCount"  -ForegroundColor Green
    }
    if ($skipCount -gt 0) {
        Write-Host "  Skipped : $skipCount (WinRM not available or dependency missing)" -ForegroundColor Yellow
    }
    else {
        Write-Host "  Skipped : $skipCount"
    }
    Write-Host "  Duration: $($duration.TotalSeconds.ToString('0.00'))s"
    Write-Host '─────────────────────────────────────────────────────────────────────' -ForegroundColor DarkGray

    if ($failCount -gt 0) {
        Write-Host ''
        Write-Host "[FAIL] $failCount test(s) failed." -ForegroundColor Red
        exit 1
    }
    else {
        Write-Host ''
        Write-Host '[PASS] All tests passed.' -ForegroundColor Green
        exit 0
    }
}
else {
    Write-Warning 'Pester returned no result object. Check configuration.'
    exit 1
}
