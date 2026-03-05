---
title: "Zero-to-Hero Contributor Guide"
description: "Practical guide for new contributors to LazyWinAdmin."
---

# Zero-to-Hero Contributor Guide

Welcome! This guide will take you from "cloned" to "coding" in the LazyWinAdmin project.

## What This Project Does
LazyWinAdmin is an enterprise-grade Windows management GUI. It allows IT administrators to quickly query hardware, services, and Active Directory information from remote systems without manually running multiple PowerShell commands.

## Prerequisites
- **PowerShell 7.4+** (Recommended)
- **Windows 10/11** or **Windows Server 2019+**
- **WinRM** enabled on your local machine (for testing remote queries)

## Environment Setup

1.  **Clone the Repo**
    ```powershell
    git clone https://github.com/dutch2005/LazyWinAdmin_GUI.git
    cd LazyWinAdmin_GUI
    ```

2.  **Verify Module Path**
    Ensure you can import the module correctly:
    ```powershell
    Import-Module ./LazyWinAdminModule/LazyWinAdminModule.psd1 -Force
    Get-Module LazyWinAdminModule
    ```

3.  **Run the App**
    ```powershell
    Start-LazyWinAdmin
    ```

## Project Structure

- **`LazyWinAdminModule/`**: The heart of the project.
  - **`Public/`**: Contains `Start-LazyWinAdmin.ps1`, the entry point `(LazyWinAdminModule/Public/Start-LazyWinAdmin.ps1:1)`.
  - **`Private/`**: The function library. If you want to add a feature (like "Get-Disks"), create a file here `(LazyWinAdminModule/Private/Get-ComputerHardware.ps1:1)`.
  - **`UI/`**: The WPF layout defined in `MainView.xaml`.
  - **`Classes/`**: System-level classes like `LazyWinAdminState`.
  - **`Tests/`**: Pester tests for all logic.

## Your First Task: Add a simple log message

1.  Open `LazyWinAdminModule/Public/Start-LazyWinAdmin.ps1`.
2.  Find the `try` block around line 35.
3.  Add `$state.Log("Application is initializing...")`.
4.  Restart the app and check the logs tab.

## Development Workflow

```mermaid
graph LR
    A[Create Branch] --> B[Write Private Function]
    B --> C[Write Pester Test]
    C --> D[Update WPF UI]
    D --> E[Add Event Handler]
    E --> F[Run All Tests]
    F --> G[Submit PR]
    
    style A fill:#2d333b,stroke:#6d5dfc,color:#e6edf3
    style B fill:#2d333b,stroke:#6d5dfc,color:#e6edf3
    style C fill:#2d333b,stroke:#6d5dfc,color:#e6edf3
    style D fill:#2d333b,stroke:#6d5dfc,color:#e6edf3
    style E fill:#2d333b,stroke:#6d5dfc,color:#e6edf3
    style F fill:#2d333b,stroke:#6d5dfc,color:#e6edf3
    style G fill:#2d333b,stroke:#6d5dfc,color:#e6edf3
```

## Code Patterns

### Adding a New Data Tab
If you want to add a new tab (e.g., "Network"), follow this template:

1.  **Logic**: Create `LazyWinAdminModule/Private/Get-NetworkInfo.ps1`.
2.  **UI**: Add a `<TabItem>` to `LazyWinAdminModule/UI/MainView.xaml`.
3.  **Event**: In `Start-LazyWinAdmin.ps1`, find the control and add a click handler:
    ```powershell
    $btnGetNetwork.Add_Click({
        Invoke-AsyncAction -ScriptBlock { Get-NetworkInfo -Computer $txtComputerName.Text } -OnCompleted {
            param($data) $lvNetwork.Items.Add($data)
        }
    })
    ```

## Running Tests
We use Pester for testing.
```powershell
Invoke-Pester ./LazyWinAdminModule/Tests/
```
(file_path: `LazyWinAdminModule/Tests/Get-ComputerService.Tests.ps1:1`)

## Glossary
- **Runspace**: A container for executing PowerShell code independently of the main thread.
- **XAML**: XML-based language used by WPF to define user interfaces.
- **CIM**: Common Information Model, the modern way to query WMI data.

## Quick Reference
- **Entry Point**: `Start-LazyWinAdmin`
- **Global State**: `$state` object
- **UI Dispatcher**: `$window.Dispatcher`
