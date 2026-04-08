# LazyWinAdmin — Modernized 2026 Edition

A complete modernisation of the classic LazyWinAdmin (2012) PowerShell GUI tool, rebuilt from scratch as a native **PowerShell 7.4+ WPF module**. Manages Windows workstations and servers through a clean tabbed interface with async operations, cloud integration, and a full Pester v5 test suite.

![LazyWinAdmin 2026](/Media/lwa-v0.4-main01.png)

---

## Requirements

| Requirement | Details |
|---|---|
| PowerShell | 7.4 or newer |
| OS | Windows 10 / 11 / Server 2019+ |
| .NET | Included with PS 7.4+ |
| Microsoft Graph modules | `Microsoft.Graph.Authentication`, `.Users`, `.Groups`, `.DeviceManagement` |
| Azure modules | `Az.Accounts`, `Az.ResourceGraph` |
| RSAT (optional) | `Rsat.ActiveDirectory` — required for the Active Directory tab |

---

## Quick Start

```powershell
# Install required modules (first time only)
Install-Module Microsoft.Graph.Authentication, Microsoft.Graph.Users, `
    Microsoft.Graph.Groups, Microsoft.Graph.DeviceManagement, `
    Az.Accounts, Az.ResourceGraph -Scope CurrentUser

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

### Software Inventory tab
- Enumerates installed software via **StdRegProv registry enumeration** (never `Win32_Product` which triggers MSI consistency repair)
- Deduplicates across 32-bit and 64-bit uninstall keys
- Optional search/filter

### Hardware Inventory tab
- Model, manufacturer, serial number, CPU, RAM, OS via CIM *(requires admin for WMI hardware classes)*
- Motherboard product, serial, version
- Disk inventory with size/free/percent

### Network tab
- All network adapters with IP, MAC, DHCP status, default gateway
- Optional filter: IP-enabled adapters only

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

### Governance & Compliance tab
- **Intune** — list managed devices with compliance state, OS, model, serial
- **Azure Resources** — resource type summary via `Search-AzGraph` (not `Get-AzResource`)

### Registry tab
- Read, write, and delete registry values via StdRegProv CIM
- Supports String, DWord, QWord, ExpandString, MultiString
- Hives: HKLM, HKCU, HKU, HKCR *(writes to HKLM require admin)*

### Cloud Auth tab
- Interactive sign-in via **Microsoft Graph** (`Connect-MgGraph`)
- Service principal sign-in (Tenant ID + Client ID + Client Secret)
- Connection state tracked in `$state.SyncHash.CloudConnected` — cloud feature buttons blocked with a friendly message when not authenticated

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
├── LazyWinAdminModule.psd1     # Module manifest (v1.1.0, requires PS 7.4+)
├── LazyWinAdminModule.psm1     # Root module — dot-sources all Private/Public files
├── Classes/
│   └── ApplicationState.ps1   # LazyWinAdminState class: SyncHash, RunspacePool, CimSessions
├── Private/                   # 16 private functions (CIM, Graph, Az, AD)
├── Public/
│   └── Start-LazyWinAdmin.ps1 # WPF window, async dispatch, all button handlers
├── UI/
│   └── MainView.xaml          # WPF layout
└── Tests/
    ├── Integrity.Tests.ps1    # File structure, manifest, XAML, ApplicationState
    ├── Functions.Tests.ps1    # All 16 private functions (178 tests, 0 failures)
    └── Run-Tests.ps1          # Test runner with summary output
```

### Async pattern

All button actions run in background thread jobs via `Start-ThreadJob`. Results are marshalled back to the WPF UI thread using `Register-ObjectEvent` on the job's `StateChanged` event and `Dispatcher.Invoke`. The UI never blocks.

### Pre-flight guards

| Guard | Blocks |
|---|---|
| `$RequireComputerName` | Any CIM operation when the computer name field is empty |
| `$RequireCloudSession` | Any Graph/Azure operation when not authenticated |

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

**178 tests, 0 failures.** Requires Pester 5.0+ (auto-installed by the runner if missing).

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
