# LazyWinAdmin GUI - Modernized (2026 Standard)

LazyWinAdmin is a comprehensive PowerShell-based management tool for Windows administrators. Originally released in 2012, this project has been completely modernized to 2026 standards, transforming from a monolithic WinForms script into a modular, thread-safe, and high-performance application.

## 🚀 2026 Modernization Highlights
The project has undergone a complete architectural overhaul to meet modern enterprise standards:

- **Modular Architecture:** Converted 13,000+ lines of code into a structured PowerShell Module (`LazyWinAdminModule`).
- **Modern UI (WPF):** Replaced legacy WinForms with a responsive **Windows Presentation Foundation (WPF)** interface using externalized XAML.
- **Async Execution (Runspaces):** Implemented multi-threading via PowerShell Runspaces. Remote operations (CIM, AD, Ping) no longer freeze the UI.
- **PowerShell 7+ Optimization:** Fully compatible with PowerShell 7.4+ (Core) while maintaining legacy compatibility where possible.
- **CIM over WMI:** Migrated all legacy `Get-WmiObject` calls to the modern, faster, and more secure `Get-CimInstance` (WinRM/WSMan).
- **Unit Testing:** Integrated **Pester** for core business logic validation.
- **CI/CD:** Automated testing via GitHub Actions.

## 🛠️ Requirements
- **PowerShell 7.4+** (Recommended) or Windows PowerShell 5.1.
- **Windows 10/11** or **Windows Server 2019/2022/2025**.
- Administrative permissions on targeted systems.
- WinRM enabled on remote targets (for CIM operations).

## 📁 Project Structure
- `LazyWinAdminModule/`: The core PowerShell module.
  - `Public/`: User-facing functions (e.g., `Start-LazyWinAdmin`).
  - `Private/`: Internal helper functions and modernized business logic.
  - `UI/`: WPF/XAML definitions for the modern interface.
  - `Tests/`: Pester unit tests.
- `Media/`: Original and updated project assets.
- `docs/`: Modernization plans and migration guides.

## 🔧 Getting Started
To launch the modernized GUI:

```powershell
# Import the module
Import-Module ./LazyWinAdminModule/LazyWinAdmin.psd1

# Start the application
Start-LazyWinAdmin
```

## ✨ Key Features
- **Real-time Connectivity:** Non-blocking Ping and WsMan testing.
- **Hardware/Software Inventory:** Modernized data collection for disks, motherboard, BIOS, and installed apps.
- **Service Management:** Responsive service query, start, stop, and restart.
- **Active Directory Integration:** Modernized AD object lookup and description management.
- **Security:** RDP status management and remote registry tools.

## 📜 Documentation
Comprehensive documentation is available in the project wiki:
- **[Principal-Level Onboarding](./docs/wiki/onboarding-principal.md)**
- **[Zero-to-Hero Contributor Guide](./docs/wiki/onboarding-zero-to-hero.md)**
- **[Getting Started](./docs/wiki/getting-started.md)**
- **[Architecture Deep Dive](./docs/wiki/architecture-deep-dive.md)**
- **[Quality & Contribution](./docs/wiki/quality-and-contribution.md)**

Other guides:
- [Web GUI Migration Plan](./WEB_GUI_MIGRATION_PLAN.md)

## 📜 Contributions
Contributions are welcome! Please ensure all new logic includes Pester tests and adheres to the modular module structure.

---
*Modernized by the LazyWinAdmin Community.*
