@{
    # PSScriptAnalyzer settings for LazyWinAdmin
    # Reference: https://github.com/PowerShell/PSScriptAnalyzer

    Severity     = @('Error', 'Warning', 'Information')

    # Exclusions are intentional — document each one's reasoning here.
    ExcludeRules = @(
        # Run-Tests.ps1 uses Write-Host deliberately for colour-coded test runner output.
        # The rest of the code base does not use Write-Host; it uses Write-Warning / Write-Verbose.
        'PSAvoidUsingWriteHost'

        # The module accepts SecureString for client secret; at the Graph boundary
        # Connect-MgGraph prefers PSCredential, which we build correctly. The rule
        # flags the conversion as "plaintext" but the value never leaves SecureString.
        'PSAvoidUsingConvertToSecureStringWithPlainText'

        # WPF button handlers are ScriptBlocks attached via Add_Click — they do not
        # have a plural-noun verb and should not; silencing a false positive.
        'PSUseSingularNouns'
    )

    Rules        = @{
        PSUseCompatibleSyntax = @{
            Enable         = $true
            TargetVersions = @('7.4', '7.5', '7.6')
        }

        PSAvoidUsingCmdletAliases = @{
            Enable    = $true
            AllowList = @()
        }

        PSUseConsistentIndentation = @{
            Enable          = $true
            IndentationSize = 4
            Kind            = 'space'
        }

        PSPlaceOpenBrace = @{
            Enable             = $true
            OnSameLine         = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }

        PSPlaceCloseBrace = @{
            Enable             = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore  = $false
        }
    }
}
