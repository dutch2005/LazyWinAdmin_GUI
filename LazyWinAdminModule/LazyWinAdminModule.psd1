@{
    RootModule        = 'LazyWinAdminModule.psm1'
    ModuleVersion     = '1.2.0'
    GUID              = '1b9e5d4a-5c20-4e3a-b892-0b13d2f9a1c2'
    Author            = 'Francois-Xavier Cat (Modernized)'
    CompanyName       = 'LazyWinAdmin'
    Copyright         = '(c) LazyWinAdmin. All rights reserved.'
    Description       = 'Modernized LazyWinAdmin GUI Module — 2026 Edition (v1.2.0)'

    # Minimum PS version per DEPS.SYSTEM in lazywinadmin.speq
    PowerShellVersion = '7.4'

    # Declaring runtime dependencies here produces a clear import-time error
    # when a required module is absent, instead of a cryptic runtime failure.
    # Maps directly to DEPS.RUNTIME in lazywinadmin.speq:
    #   microsoft-graph -> Microsoft.Graph.Authentication (core auth + context)
    #   az              -> Az.Accounts (Connect-AzAccount, Get-AzContext)
    #                      Az.ResourceGraph (Search-AzGraph)
    # NOTE: ThreadJob is NOT listed here — Start-ThreadJob is an inbox cmdlet
    # in PowerShell 7.4+ (enforced by PowerShellVersion = '7.4' above).
    # Listing 'ThreadJob' in RequiredModules causes Import-Module to fail because
    # PS cannot resolve it as a named module even though the cmdlet is available.
    RequiredModules   = @(
        'Microsoft.Graph.Authentication',
        'Microsoft.Graph.Users',
        'Microsoft.Graph.Groups',
        'Microsoft.Graph.DeviceManagement',
        'Az.Accounts',
        'Az.ResourceGraph'
    )

    FunctionsToExport = @('Start-LazyWinAdmin')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
