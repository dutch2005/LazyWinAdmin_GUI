---
title: "Principal-Level Onboarding Guide"
description: "High-level architectural deep-dive for senior engineers."
---

# Principal-Level Onboarding Guide

Welcome to the 2026 modernization of LazyWinAdmin. This document outlines the architectural philosophy and core invariants of the system.

## System Philosophy & Design Principles

LazyWinAdmin has evolved from a monolithic PowerShell script into a modular, enterprise-grade RMM tool. The core invariant of the 2026 version is **UI Responsiveness**. In previous versions, long-running WMI or AD queries would "freeze" the WinForms interface. The modern version solves this through strict separation of concerns and multi-threading.

### Core Architectural Choice: Async-First
Every remote operation (CIM, AD, Ping) MUST execute in a background Runspace. The main thread is reserved exclusively for the WPF UI loop.

**Pseudocode Comparison (C# vs PowerShell):**
```csharp
// C# equivalent of our PowerShell pattern
public async Task RunQuery(string computer) {
    SetBusy(true);
    var result = await Task.Run(() => GetCimData(computer));
    UpdateUI(result);
    SetBusy(false);
}
```

```powershell
# Our PowerShell Implementation (Start-LazyWinAdmin.ps1:115)
Invoke-AsyncAction -ScriptBlock { Get-CimData -Computer $t } -OnCompleted { param($res) Update-UI $res }
```

## Architecture Overview

The system follows a modular pattern with a centralized state controller.

```mermaid
graph TD
    subgraph UI_Layer ["Presentation (Main Thread)"]
        WPF[WPF MainView.xaml]
        Events[Event Handlers]
    end

    subgraph Logic_Layer ["Business Logic (Runspace Pool)"]
        CIM[CIM/WMI Modules]
        AD[Active Directory Modules]
        Inventory[Software/Hardware Modules]
    end

    subgraph State_Layer ["Infrastructure"]
        AppState[LazyWinAdminState Class]
        SyncHash[Synchronized Hashtable]
    end

    WPF --> Events
    Events --> AppState
    Events -- "Invoke-AsyncAction" --> Logic_Layer
    Logic_Layer -- "Dispatcher.Invoke" --> WPF
    Logic_Layer <--> SyncHash
    
    style UI_Layer fill:#161b22,stroke:#30363d,color:#e6edf3
    style Logic_Layer fill:#161b22,stroke:#30363d,color:#e6edf3
    style State_Layer fill:#161b22,stroke:#30363d,color:#e6edf3
    style WPF fill:#2d333b,stroke:#6d5dfc,color:#e6edf3
    style Events fill:#2d333b,stroke:#6d5dfc,color:#e6edf3
    style AppState fill:#2d333b,stroke:#6d5dfc,color:#e6edf3
    style SyncHash fill:#2d333b,stroke:#6d5dfc,color:#e6edf3
```

## Key Abstractions

1.  **`LazyWinAdminState` Class** `(LazyWinAdminModule/Classes/ApplicationState.ps1:3)`: Encapsulates the `RunspacePool` and the `SyncHash`. This is the single source of truth for the application's lifecycle.
2.  **`Invoke-AsyncAction` Helper** `(LazyWinAdminModule/Public/Start-LazyWinAdmin.ps1:115)`: A higher-order function that abstracts the complexity of starting a `ThreadJob`, passing arguments safely into a fresh runspace, and marshalling the result back to the WPF Dispatcher.

## Data Flow: Async Command Execution

When a user clicks a button (e.g., "Ping"), the following sequence occurs:

```mermaid
sequenceDiagram
    autonumber
    participant UI as WPF Main Thread
    participant AA as Invoke-AsyncAction
    participant RP as Runspace Pool
    participant PL as Private Logic

    UI->>AA: Button_Click (ComputerName)
    AA->>UI: SetProgressBar(Busy)
    AA->>RP: Start-ThreadJob (ScriptBlock + Args)
    RP->>PL: Execute (e.g., Get-ComputerUptime)
    PL-->>RP: Return Result
    RP-->>AA: Job Completed
    AA->>UI: Dispatcher.Invoke (OnCompleted)
    UI->>UI: Update Output Label
    AA->>UI: SetProgressBar(Ready)
```

## Dependency Rationale

| Dependency | Purpose | Replaces |
| :--- | :--- | :--- |
| **WPF (XAML)** | Modern, DPI-aware vector UI. | WinForms (raw System.Windows.Forms) |
| **RunspacePool** | Managed multi-threading for performance. | Single-threaded execution |
| **CIM Cmdlets** | Modern WS-Man based remote management. | WMIv1 (Get-WmiObject) |
| **Pester** | Automated unit and integration testing. | Manual verification |

## Known Technical Debt & Strategic Direction

- **PowerShell 5.1 Fallback**: While optimized for PS 7.4+ `(LazyWinAdminModule/LazyWinAdminModule.psd1:10)`, some logic still uses older .NET types for widest compatibility.
- **Credential Management**: Currently relies on the execution context's credentials. Future roadmap includes `PSCredential` delegation via the `LazyWinAdminState`.

## References
- `LazyWinAdminModule/Classes/ApplicationState.ps1`
- `LazyWinAdminModule/Public/Start-LazyWinAdmin.ps1`
- `LazyWinAdminModule/Private/Get-ComputerHardware.ps1`
- `LazyWinAdminModule/UI/MainView.xaml`
- `lazywinadmin-modernization.md`
