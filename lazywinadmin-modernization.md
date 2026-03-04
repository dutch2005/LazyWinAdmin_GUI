# LazyWinAdmin GUI - Modernization Plan (2026 Standards)

## Goal
Transform the 2012-era monolithic WinForms PowerShell script (`LazyWinAdmin.ps1` - 13,000+ lines) into a highly maintainable, modern, non-blocking tool compatible with PowerShell 7+ and current Windows environments.

## Modernization Audit & Key Findings

1. **Monolithic Architecture**
   - **Current:** All 13,120 lines are in a single `.ps1` file.
   - **Modern Standard:** Convert to a structured PowerShell Module (`.psd1` / `.psm1`). Separate the GUI logic, event handlers, and business logic into modular files (e.g., `Public/`, `Private/`, `Classes/`).

2. **Archaic GUI Technology & Threading**
   - **Current:** Uses raw `System.Windows.Forms` injected via PowerShell, and uses .NET Framework 2.0 assemblies. It operates on a single thread, meaning the GUI "freezes" during long operations (like AD queries or WMI calls).
   - **Modern Standard:** 
     - **UI:** Upgrade to **WPF (Windows Presentation Foundation)** using external `.xaml` files for cleaner UI definitions, *or* migrate to a web-based dashboard like **PowerShell Universal (Pode)** if a web GUI is preferred.
     - **Threading:** Implement **Runspaces** (via `ThreadJob` or runspace pools) so the UI remains responsive while background tasks execute.

3. **Global State Management**
   - **Current:** Heavy reliance on global variables (e.g., `$global:ComputerName`).
   - **Modern Standard:** Pass state via a synchronized hashtable (essential for Runspaces) or use PowerShell Classes (`class ApplicationState { ... }`) to encapsulate state safely.

4. **Outdated Cmdlets & APIs**
   - **Current:** Likely relies heavily on `Get-WmiObject` and old Active Directory ADSI accelerators.
   - **Modern Standard:** 
     - Replace all `Get-WmiObject` calls with `Get-CimInstance` (WMIv1 is deprecated/slower; CIM uses WinRM/WSMan which is firewall-friendly).
     - Ensure compatibility with PowerShell 7+ (Core) rather than being locked to Windows PowerShell 5.1.

5. **Error Handling & Code Quality**
   - **Current:** Basic parameter validation and inline errors.
   - **Modern Standard:** 
     - Apply `Set-StrictMode -Version Latest`.
     - Implement proper `try/catch/finally` blocks everywhere.
     - Use an established logging framework.

---

## Tasks (Proposed Execution Phases)

- [x] **Task 1: Scaffold Module Structure** → Verify: Create `LazyWinAdmin.psd1`, `.psm1`, and folders for `Public`, `Private`, and `UI`.
- [x] **Task 2: Decouple Business Logic** → Verify: Extract core functions (ping, query AD, check services) into separate `.ps1` files in the `Private/` folder.
- [x] **Task 3: Modernize Cmdlets** → Verify: Regex replace `Get-WmiObject` with `Get-CimInstance` and update WMI syntax across extracted scripts.
- [x] **Task 4: Build Modern UI (WPF)** → Verify: Convert the WinForms layout into a `MainView.xaml` file and load it using `[Windows.Markup.XamlReader]::Load()`.
- [x] **Task 5: Implement Threading (Runspaces)** → Verify: Wrap the execution of long-running tasks in thread jobs updating a thread-safe UI dispatcher.
- [x] **Task 6: Strict Mode & Cleanup** → Verify: Add strict typing, remove `$global` scopes in favor of a shared `[hashtable]::Synchronized(@{})` state, and ensure PS7 compatibility.

## Done When
- [ ] The application launches via `Import-Module LazyWinAdmin; Start-LazyWinAdmin`.
- [ ] The UI does not freeze when querying a remote computer.
- [ ] The codebase runs cleanly in PowerShell 7.4+.
