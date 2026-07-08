function Assert-ModuleRequirement {
    <#
    .SYNOPSIS
        Checks if a specified module is installed and meets the minimum version requirement.
        Installs it from the PSGallery if it's missing or outdated.
    .DESCRIPTION
        This function handles Just-In-Time (JIT) dependencies for LazyWinAdmin GUI features.
        It searches for the module locally, checks its version against the MinimumVersion (if provided),
        and uses Install-Module -Scope CurrentUser to install or update the module if necessary.
    .PARAMETER ModuleName
        The name of the PowerShell module (e.g., 'ExchangeOnlineManagement', 'ActiveDirectory').
    .PARAMETER MinimumVersion
        The minimum required version. If the local version is lower, the module will be updated.
    .EXAMPLE
        Assert-ModuleRequirement -ModuleName 'ExchangeOnlineManagement' -MinimumVersion '3.0.0'
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [string]$MinimumVersion
    )

    Write-Verbose "Checking requirements for module: $ModuleName"
    $installedModules = Get-Module -Name $ModuleName -ListAvailable | Sort-Object -Property @{Expression={[version]$_.Version}; Descending=$true}
    $latestInstalled = $installedModules | Select-Object -First 1

    $needsInstall = $false

    if (-not $latestInstalled) {
        $needsInstall = $true
        Write-Verbose "Module '$ModuleName' is not installed locally."
    }
    elseif ($MinimumVersion -and ([version]$latestInstalled.Version -lt [version]$MinimumVersion)) {
        $needsInstall = $true
        Write-Verbose "Module '$ModuleName' version ($($latestInstalled.Version)) is lower than required ($MinimumVersion)."
    }

    if ($needsInstall) {
        Write-Verbose "Attempting to install module '$ModuleName'..."
        
        # Display a 5-second auto-closing notification so the user knows why the app might pause
        $wshell = New-Object -ComObject Wscript.Shell
        $wshell.Popup("Module '$ModuleName' is required but not installed.`n`nIt is being downloaded and installed in the background right now. This may take a moment...", 5, "LazyWinAdmin - Installing Dependency", 0x40) | Out-Null

        try {
            $installParams = @{
                Name               = $ModuleName
                Scope              = 'CurrentUser'
                Force              = $true
                AllowClobber       = $true
                ErrorAction        = 'Stop'
            }
            if ($MinimumVersion) {
                $installParams.MinimumVersion = $MinimumVersion
            }

            # Install PackageProvider NuGet if missing
            $nuGetProvider = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue
            if (-not $nuGetProvider -or $nuGetProvider.Version -lt [version]'2.8.5.201') {
                Write-Verbose "Installing NuGet package provider..."
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction SilentlyContinue | Out-Null
            }

            # Trust PSGallery temporarily to avoid prompts
            $psGallery = Get-PSRepository -Name 'PSGallery' -ErrorAction SilentlyContinue
            $wasTrusted = $false
            if ($psGallery -and $psGallery.InstallationPolicy -ne 'Trusted') {
                $wasTrusted = $true
                Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction SilentlyContinue
            }

            # Try with AcceptLicense, fallback if parameter is invalid
            try {
                Install-Module @installParams -AcceptLicense -ErrorAction Stop
            }
            catch [System.Management.Automation.ParameterBindingException] {
                Install-Module @installParams -ErrorAction Stop
            }

            if ($wasTrusted) {
                Set-PSRepository -Name 'PSGallery' -InstallationPolicy Untrusted -ErrorAction SilentlyContinue
            }

            Write-Verbose "Successfully installed module '$ModuleName'."
        }
        catch {
            throw "Failed to install required module '$ModuleName'. Please install it manually: Install-Module -Name $ModuleName -Scope CurrentUser`nError: $_"
        }
    }

    return $true
}
