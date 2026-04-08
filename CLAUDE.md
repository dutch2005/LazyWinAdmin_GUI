# Claude Code Instructions — LazyWinAdmin GUI

## Always do when making changes

- **Update README.md** when a feature or milestone is completed. The README should always reflect what is currently working and what is actively being worked on. Update requirements, feature list, usage instructions, and version history when something meaningful ships — not on every intermediate commit.

## Project overview

This is a **PowerShell 7.4+ WPF desktop module** (`LazyWinAdminModule`) for managing Windows workstations and servers. It is NOT a web application. There are no Node.js servers, no React components, no web ports.

## Key conventions

- All private functions live in `LazyWinAdminModule/Private/`
- The single public entry point is `Start-LazyWinAdmin` in `LazyWinAdminModule/Public/`
- The WPF layout is in `LazyWinAdminModule/UI/MainView.xaml`
- `ApplicationState.ps1` in `LazyWinAdminModule/Classes/` holds shared state
- Tests are Pester v5 only — run via `LazyWinAdminModule/Tests/Run-Tests.ps1`
- Always run the test suite before committing functional changes

## Things to avoid

- Do NOT add `.lovable/` files or Lovable.dev integrations — the project is no longer hosted there
- Do NOT add `ThreadJob` to `RequiredModules` in the manifest — it is inbox in PS 7.4+
- Do NOT use `Get-Content` + `Invoke-Expression` for loading scripts — use `-InitializationScript` dot-source pattern
- Do NOT use `Win32_Product` WMI class — it triggers MSI consistency repair; use StdRegProv registry enumeration instead
- Do NOT surface exception detail (stack traces, credential fragments) in UI return values
