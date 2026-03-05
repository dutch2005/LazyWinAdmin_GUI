# LazyWinAdmin Web GUI Migration Plan

## Executive Summary
Migrating LazyWinAdmin from a WPF desktop application to a **Web-based GUI** is **highly viable** and strongly recommended for modern IT teams. Because the business logic has already been cleanly decoupled into modular `.ps1` files in the `Private/` directory, the backend is effectively API-ready.

Moving to a web model provides massive security benefits: it removes the need for 1st and 2nd line admins to have direct administrative access to target machines. Instead, the web server acts as a secure proxy (using Just Enough Administration - JEA or a gMSA).

## Proposed Architecture Options

### Option 1: PowerShell Universal (Recommended for Enterprise)
*   **What it is:** A commercial (but affordable) platform built specifically to turn PowerShell scripts into Web APIs and Dashboards.
*   **Why it fits:** It has built-in support for OIDC (Entra ID), Role-Based Access Control (RBAC), and secrets management.
*   **Viability:** **Extremely High**. You can literally map your existing `Private/*.ps1` scripts to API endpoints or Dashboard buttons in minutes.

### Option 2: Pode / Pode.Web (Recommended for Open Source)
*   **What it is:** A cross-platform open-source web framework written purely in PowerShell.
*   **Why it fits:** Free, supports Windows Authentication and OAuth2, and allows building REST APIs directly from PowerShell.
*   **Viability:** **High**, but requires more manual coding for the frontend and RBAC logic.

---

## Security & Role-Based Access Control (RBAC)

To support 1st, 2nd, and 3rd line admins, the application must implement strict RBAC.

### Authentication
*   **Cloud/Hybrid:** OIDC using Microsoft Entra ID.
*   **On-Premise Only:** Windows Integrated Authentication (Kerberos).

### Authorization Tiers
Map Active Directory or Entra ID groups to specific roles within the Web App:

*   **Tier 1 (Helpdesk / 1st Line):**
    *   **Permissions:** Read-only tasks and safe remediations.
    *   **Allowed Scripts:** `Get-ComputerHardware`, `Get-ComputerNetwork`, `Get-ComputerSoftware`, `Get-ComputerUptime`, `Test-ComputerPort`.
*   **Tier 2 (Sysadmin / 2nd Line):**
    *   **Permissions:** Operational state changes.
    *   **Allowed Scripts:** `Get-ComputerService`, *Restart* Services, `Get-ComputerLocalUser`, Enable/Disable RDP.
*   **Tier 3 (Infrastructure / 3rd Line):**
    *   **Permissions:** Destructive or highly privileged actions.
    *   **Allowed Scripts:** `Invoke-ComputerRegistry` (Set/Remove), Cloud governance tasks (`Get-AzureResourceSummary`).

### Execution Security (The "Proxy" Model)
Currently, admins run the GUI on their local machines, requiring them to have Domain Admin or local admin rights on the target PCs. 
**In the Web GUI model:**
1. The user authenticates to the Web App.
2. The Web App validates their RBAC role.
3. The Web App executes the script using a **Group Managed Service Account (gMSA)** or via **PowerShell JEA (Just Enough Administration)**.
*Benefit:* 1st line admins never get the actual admin credentials. They only get the button.

---

## Environment Setup & Toggles (On-Prem vs Cloud)

To support different customer setups, the application will use a central configuration file (e.g., `config.json` or `config.psd1`) to control UI visibility and loaded modules.

```json
{
  "Environment": {
    "Mode": "Hybrid", // Options: "OnPrem", "Cloud", "Hybrid"
    "Features": {
      "EnableRegistryEditing": false,
      "EnableRDPManagement": true
    }
  }
}
```

### UI Behavior based on Mode:
*   **`OnPrem` Mode:** 
    *   Hides the "Cloud Auth", "Entra ID", "Intune Devices", and "Azure Resources" tabs.
    *   Does not load `Get-EntraIdentity.ps1` or `Get-IntuneDevice.ps1` into memory.
*   **`Cloud` Mode:** 
    *   Hides "Local Accounts", "Hardware Inventory" (if strictly cloud-native MDM), and "Registry".
    *   Focuses purely on Graph API and Intune endpoints.
*   **`Hybrid` Mode:** 
    *   Displays all authorized tabs.

## Next Steps for Migration
1.  **Select Framework:** Decide between PowerShell Universal (rapid development) or Pode (free/open-source).
2.  **API Wrapper:** Create a REST API layer that wraps the existing `LazyWinAdminModule\Private` scripts.
3.  **Auth Implementation:** Implement OIDC/Windows Auth and define the L1/L2/L3 role mappings.
4.  **Frontend Build:** Recreate the XAML tabs as Web Dashboard pages (HTML/CSS/JS or Pode.Web).