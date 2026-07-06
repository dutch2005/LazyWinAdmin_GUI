# LazyWinAdmin — Modernized 2026 Edition

A complete modernisation of the classic LazyWinAdmin (2012) PowerShell GUI tool, rebuilt from scratch as a native **PowerShell 7.4+ WPF module**. Manages Windows workstations and servers through a clean tabbed interface with async operations, cloud integration, and a full Pester v5 test suite.

![LazyWinAdmin v1.3.0 — main view](/Media/lwa-v1.3-main.png)

<details>
<summary>More screenshots (v1.3.0)</summary>

| Services tab | Device Compliance tab |
|---|---|
| ![Services](/Media/lwa-v1.3-services.png) | ![Compliance](/Media/lwa-v1.3-compliance.png) |

| Governance & Compliance | Cloud Auth |
|---|---|
| ![Governance](/Media/lwa-v1.3-governance.png) | ![Cloud Auth](/Media/lwa-v1.3-cloud-auth.png) |

</details>

> **Before/after:** the original 2012 WinForms interface is preserved in [`Media/lwa-v0.4-main01.png`](/Media/lwa-v0.4-main01.png).

---

## Requirements

| Requirement | Details |
|---|---|
| PowerShell | 7.4 or newer |
| OS | Windows 10 / 11 / Server 2019+ |
| .NET | Included with PS 7.4+ |
| Microsoft Graph modules | `Microsoft.Graph.Authentication`, `.Users`, `.Groups`, `.DeviceManagement` |
| Azure modules | `Az.Accounts`, `Az.ResourceGraph` |
| Exchange (optional) | `ExchangeOnlineManagement` — required for the Exchange tab |
| RSAT (optional) | `Rsat.ActiveDirectory` — required for the Active Directory tab |

---

## Quick Start

```powershell
# Install required modules (first time only)
Install-Module Microsoft.Graph.Authentication, Microsoft.Graph.Users, `
    Microsoft.Graph.Groups, Microsoft.Graph.DeviceManagement, `
    Az.Accounts, Az.ResourceGraph -Scope CurrentUser

# Optional: Exchange tab
Install-Module ExchangeOnlineManagement -Scope CurrentUser

# Import and launch
Import-Module .\LazyWinAdminModule\LazyWinAdminModule.psd1 -Force
Start-LazyWinAdmin
```

> **Tip:** Some features (hardware inventory, RDP toggle, registry writes) require local Administrator rights. The status bar shows your elevation level and offers a **Restart as Admin** button when needed.

---

## Features

### System & Network tab
- **Ping** — tests WinRM port 5985 reachability (the actual transport used by CIM)
- **Get Uptime** — last boot time formatted as `D Days H Hours M Minutes S Seconds`
- **Enable / Disable RDP** — toggles `fDenyTSConnections` registry key and Windows Firewall rule group *(requires admin)*

### Services tab
- List all services or filter to stopped-but-auto-start services
- Search by service name
- **Start / Stop / Restart** the selected service *(requires admin)* *(new in v1.3.0)*
- **Export CSV** — saves the current list to a file *(new in v1.3.0)*
- Result count displayed after each query *(new in v1.3.0)*
- Right-click any row → **Copy Row to Clipboard** *(new in v1.3.0)*

### Software Inventory tab
- Enumerates installed software via **StdRegProv registry enumeration** (never `Win32_Product` which triggers MSI consistency repair)
- Deduplicates across 32-bit and 64-bit uninstall keys
- Optional search/filter
- **Export CSV** + result count *(new in v1.3.0)*

### Hardware Inventory tab
- Model, manufacturer, serial number, CPU, RAM, OS via CIM *(requires admin for WMI hardware classes)*
- Motherboard product, serial, version
- Disk inventory with size/free/percent

### Network tab
- All network adapters with IP, MAC, DHCP status, default gateway
- Optional filter: IP-enabled adapters only
- **Export CSV** + adapter count *(new in v1.3.0)*

### Identity tab — Local Accounts
- Local users (no password hash exposure — `Password` property intentionally excluded)
- Local groups

### Identity tab — Entra ID (Cloud)
- Users and groups from **Microsoft Entra ID** via Microsoft Graph
- OData injection guard on search terms
- Requires cloud authentication (Cloud Auth tab)

### Identity tab — Active Directory
- Computer, user, and group queries via RSAT
- LDAP injection guard on AdFilter
- `SamAccountName` excluded from user results (PII protection)
- Requires RSAT ActiveDirectory module

### Device Compliance tab *(new in v1.2.0)*
Reads and remediates local device compliance settings — no network required:

| Check | Remediation |
|---|---|
| Location Services | Re-enables the `lfsvc` service and clears policy overrides |
| OneDrive | Uninstalls OneDrive client cleanly (process + registry + files) |
| Outlook External Images | Sets the registry flag that blocks automatic external image loading |
| Windows Update active hours | Writes configurable start/end hours to HKLM (dynamic — enter any 0-23 value) |
| UWF (Unified Write Filter) | Reports current UWF state (read-only — no remediation needed) |

### Exchange tab *(new in v1.2.0)*
Requires `ExchangeOnlineManagement` module and a one-time sign-in via the **Exchange › Connection** sub-tab.

- **View Mailbox Permissions** — lists all shared mailboxes a user has FullAccess or SendAs on
- **Mirror Permissions** — copies all mailbox permissions from a source user to a target user
- **Grant Permissions** — grants FullAccess + SendAs on a specific mailbox to a user

### Governance & Compliance tab
- **Intune** — list managed devices with compliance state, OS, model, serial; **Export CSV** + device count *(count new in v1.3.0)*
- **Intune Scripts** *(new in v1.2.0)* — browse and optionally download all scripts deployed via Intune (`deviceManagement/deviceManagementScripts`). Uses `Invoke-MgGraphRequest` against the beta endpoint — no deprecated `Microsoft.Graph.Intune` needed.
- **Azure Resources** — resource type summary via `Search-AzGraph` (not `Get-AzResource`)

### Registry tab
- Read, write, and delete registry values via StdRegProv CIM
- Supports String, DWord, QWord, ExpandString, MultiString
- Hives: HKLM, HKCU, HKU, HKCR *(writes to HKLM require admin)*

### Cloud Auth tab
- Interactive sign-in via **Microsoft Graph** (`Connect-MgGraph`)
- Service principal sign-in (Tenant ID + Client ID + Client Secret)
- Connection state tracked in `$state.SyncHash.CloudConnected` — cloud feature buttons blocked with a friendly message when not authenticated

### RMM & PIM Features tab *(new in v1.4.0)*
A comprehensive suite for endpoint management and identity protection, featuring:
- **On-Premise Tools**: Remote Process Management, Event Logs extraction, Volume checking, SMB share/session enumeration, pending Windows Updates retrieval, and Interactive PSRemoting sessions (`Enter-LWAComputerSession`).
- **Cloud Identity (PIM)**: Integrated Just-In-Time PIM elevation (`Invoke-LWAEntraPIMElevation`). Allows securely fetching BitLocker Recovery Keys, triggering Intune Device Syncs, querying Entra ID Sign-in Logs, forcefully Revoking user sessions, and Resetting user MFA with Ticket/Justification auditing.

---

## Admin elevation

The status bar always shows your elevation level:

| Status | Meaning |
|---|---|
| `Administrator` (green) | Full functionality available |
| `(!) Standard User` (amber) | Hardware, RDP, and registry writes may fail |

Click **Restart as Admin** in the status bar to relaunch elevated. Features that fail due to insufficient rights display a clear hint in the output box.

---

## Architecture

```
LazyWinAdminModule/
├── LazyWinAdminModule.psd1     # Module manifest (v1.3.1, requires PS 7.4+)
├── LazyWinAdminModule.psm1     # Root module — dot-sources all Private/Public files
├── Classes/
│   └── ApplicationState.ps1   # LazyWinAdminState class: SyncHash, RunspacePool, CimSessions, UIQueue
├── Private/                   # 24 private functions (CIM, Graph, Az, AD, Exchange, Compliance)
├── Public/
│   └── Start-LazyWinAdmin.ps1 # WPF window, async dispatch, all button handlers
├── UI/
│   └── MainView.xaml          # WPF layout (11 tabs)
└── Tests/
    ├── Integrity.Tests.ps1                 # File structure, manifest, XAML, ApplicationState
    ├── Functions.Tests.ps1                 # Core private functions
    ├── Test-ComputerPort.Tests.ps1         # TCP port probe
    ├── Connect-ExchangeSession.Tests.ps1   # Exchange Online connection
    ├── Get-DeviceComplianceStatus.Tests.ps1
    ├── Get-ExchangeMailboxPermission.Tests.ps1
    ├── Get-IntuneManagementScript.Tests.ps1
    ├── Set-DeviceComplianceItem.Tests.ps1
    ├── Set-ExchangeMailboxPermission.Tests.ps1
    ├── Get-ComputerRegistryValue.Tests.ps1
    └── Run-Tests.ps1          # Test runner (auto-discovers *.Tests.ps1)
```

### Async pattern

All button actions run in background thread jobs via `Start-ThreadJob`. Completed results are enqueued into a `ConcurrentQueue` by a `Register-ObjectEvent` handler, then dequeued by a `DispatcherTimer` (50 ms tick) running on the WPF UI thread. This eliminates all cross-thread delegate issues and ensures the UI never blocks — even when multiple jobs complete simultaneously.

> **v1.1.x note:** Earlier versions used `Dispatcher.InvokeAsync([action]{…})` which proved fragile under certain runspace/closure conditions. The ConcurrentQueue pattern replaces it entirely.

### Local CIM routing *(fixed in v1.2.0)*

In PowerShell 7+, `Get-CimInstance -ComputerName localhost` routes through WSMan (WinRM) even for the local machine. If WinRM is not running, CIM jobs stall for the full connection timeout (30 s), saturate the `Start-ThreadJob` pool (5 slots), and freeze the UI. All CIM-based private functions now detect a local target and omit `-ComputerName` entirely, using a direct in-process CIM session instead.

### Pre-flight guards

| Guard | Blocks |
|---|---|
| `$RequireComputerName` | Any CIM operation when the computer name field is empty |
| `$RequireCloudSession` | Any Graph/Azure operation when not authenticated |
| `$RequireExchangeSession` | Any Exchange operation when Exchange is not connected |

---

## Running the tests

```powershell
# Summary output
pwsh -NoProfile -File .\LazyWinAdminModule\Tests\Run-Tests.ps1

# Detailed output
pwsh -NoProfile -File .\LazyWinAdminModule\Tests\Run-Tests.ps1 -Output Detailed

# Single suite
pwsh -NoProfile -File .\LazyWinAdminModule\Tests\Run-Tests.ps1 -Suite Integrity
```

**309 tests, 0 failures.** Requires Pester 5.0+ (auto-installed by the runner if missing).

---

## Dev launch configurations

`.claude/launch.json` contains three configurations:

| Name | Command |
|---|---|
| LazyWinAdmin GUI | `pwsh` → `Import-Module … ; Start-LazyWinAdmin` |
| Pester Tests (Detailed) | `pwsh -File Run-Tests.ps1 -Output Detailed` |
| Pester Tests (Normal) | `pwsh -File Run-Tests.ps1` |

---

## Version history

### v1.4.0 — 2026 (RMM & PIM Edition)
- **Advanced RMM & PIM Tab**: 13 brand new fully-integrated functions for complete endpoint and identity governance.
- **Just-In-Time PIM Elevation**: Added `Test-LWAEntraRole` and `Invoke-LWAEntraPIMElevation` to seamlessly elevate privileges for cloud actions (BitLocker, Intune Sync) requiring a justification ticket (e.g. `INC12345`).
- **Identity Protection**: Integrated tools to fetch Entra ID sign-in logs, reset MFA, and revoke active sessions directly from the GUI.
- **On-Premise Diagnostics**: Added Process Management, Event Logs, Windows Update checks, SMB Session management, Volumes, and interactive PSRemoting via CIM/WMI modules.
- **UI Async Fixes**: Rewrote background thread serialization so massive CIM instance returns (like processes or event logs) are parsed locally in the Runspace, preventing WPF dispatcher freezes.
- **Extensive Test Coverage**: Total test count increased to **439 tests** with 0 failures to cover all 13 new Cloud and On-Premise scripts.

### v1.3.1 — 2026 (clean-code & full test coverage)
- **309 Pester v5 tests, 0 failures** (up from 228) — 8 new test files covering all previously untested private functions: `Test-ComputerPort`, `Connect-ExchangeSession`, `Get-DeviceComplianceStatus`, `Get-ExchangeMailboxPermission`, `Get-IntuneManagementScript`, `Set-DeviceComplianceItem`, `Set-ExchangeMailboxPermission`, `Get-ComputerRegistryValue`
- **Zero PSScriptAnalyzer warnings/errors** across all production code (Classes, Private, Public) and all test files
- **GitHub Actions CI/CD** — `.github/workflows/ci.yml` blocks any PR or push with lint issues or test failures; separate lint steps for Classes, Private, Public, Tests with appropriate rule exclusions for test files
- **Trailing whitespace removed** from 4 private functions (`Test-ComputerPort`, `Get-ComputerRegistryValue`, `Get-ComputerService`, `Get-ComputerUptime`)
- **`Get-DeviceComplianceStatus` strict-mode fix** — null-guards added to all 5 compliance checks so the function is safe under `Set-StrictMode -Version Latest`
- **`Set-ExchangeMailboxPermission` syntax fix** — replaced invalid `return if (...)` expression with standard conditional return
- **`Run-Tests.ps1` dynamic discovery** — test runner now auto-discovers all `*.Tests.ps1` files instead of hardcoding two suites; `-Suite Functions` runs all non-Integrity suites
- **`PSScriptAnalyzerSettings.psd1`** — severity narrowed to `Error, Warning` so the CI threshold is consistent with the settings file

### v1.3.0 — 2026 (2026 refactor & value-add pass)
- **Service control** — Start, Stop, and Restart the selected service directly from the Services tab via new CIM-based `Invoke-ComputerServiceControl` private function *(requires admin)*
- **Export to CSV** — "Export CSV" button on Services, Software, Network, Intune Devices, and Mailbox Permissions tabs; opens SaveFileDialog, writes UTF-8 CSV
- **Result count labels** — all major list views now show "N item(s)" after each query (Services, Software, Network, Intune Devices, Mailbox Permissions)
- **Status bar clock** — live `HH:mm:ss` display in the status bar (second DispatcherTimer, 1 s tick)
- **Ping refactored** — now uses `Test-ComputerPort` (private function) instead of inline `Test-NetConnection`, consistent with the rest of the codebase
- **Copy to Clipboard** — right-click any row in any ListView to copy the tab-separated values to the clipboard (context menu added to all 12 list views in code)
- **16 new Pester tests** for `Invoke-ComputerServiceControl` (parameter validation, Start/Stop/Restart, non-zero return codes, error path, local routing)
- 228 Pester v5 tests, 0 failures (up from 212)

### v1.2.0 — 2026
- **Device Compliance tab** — check and remediate Location Services, OneDrive, Outlook external images, Windows Update active hours (dynamic), UWF state. Runs locally, no network required.
- **Exchange tab** — view, mirror, and grant mailbox permissions via Exchange Online. Requires `ExchangeOnlineManagement` module. Auth tracked separately from Graph (`$state.SyncHash.ExchangeConnected`).
- **Intune Scripts sub-tab** — browse and download all Intune-deployed scripts via `deviceManagement/deviceManagementScripts` beta endpoint.
- **CIM local routing fix** — all 10 CIM-based private functions now detect localhost targets and skip `-ComputerName`, eliminating WinRM dependency and the associated UI freeze.
- **Async architecture fix** — replaced `Dispatcher.InvokeAsync([action]{…})` with `ConcurrentQueue` + `DispatcherTimer` (50 ms tick). Event handlers only enqueue; UI thread only dequeues. No cross-thread delegate issues possible.
- **`$RequireExchangeSession` guard** — Exchange operations blocked with a clear message when Exchange is not connected.
- 212 Pester v5 tests, 0 failures (up from 178)

### v1.1.0 — 2026 (Modernized Edition)
- Complete rewrite as a PowerShell 7.4+ WPF module
- Async UI via `Start-ThreadJob` + `Register-ObjectEvent` — no blocking
- Cloud integration: Entra ID (users/groups), Intune devices, Azure Resource Graph
- Active Directory support (RSAT)
- Admin elevation detection with Restart as Admin button
- Registry CRUD via StdRegProv (no `Win32_Product`)
- Pre-flight guards for cloud auth and computer name
- OData/LDAP injection protection on all search inputs
- 178 Pester v5 tests, 0 failures
- `.claude/launch.json` dev launch configurations

### v0.4 — 2012 (Original)
- PowerShell 2.0 WinForms GUI built with Sapien PowerShell Studio 2012
- On-premises only: services, software, hardware, network, AD, RDP, registry
- See legacy source in `LazyWinAdmin/` and `Sources/`

---

## Contributing

Contributions are welcome. See [LICENSE](LICENSE) for details.
