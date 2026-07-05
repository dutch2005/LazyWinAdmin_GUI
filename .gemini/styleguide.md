# LazyWinAdmin — Style Guide for Gemini Code Assist

Gemini reads this file when reviewing PRs. Keep it concise and prescriptive.

## Language and stack

- **PowerShell 7.4+** (minimum). Windows-only (WPF). Not cross-platform.
- WPF / XAML for UI. No WinForms, no MAUI, no WinUI.
- Microsoft Graph PowerShell SDK (`Microsoft.Graph.*`) for Entra / Intune.
- Az PowerShell (`Az.Accounts`, `Az.ResourceGraph`) for Azure.
- Pester **v5** for tests (not v3/v4).

## Hard rules (from `CLAUDE.md` and `lazywinadmin.speq`)

1. **Never** use `Get-WmiObject`. Always `Get-CimInstance` / `Invoke-CimMethod`.
2. **Never** use `Win32_Product` — it triggers an MSI consistency repair on the
   target machine. For software inventory, enumerate the uninstall registry
   keys via `StdRegProv`.
3. **Never** use `Get-Content + Invoke-Expression` to load code. Use
   `Start-ThreadJob -InitializationScript { . $privateFile }`.
4. **Never** add `ThreadJob` to `RequiredModules` in the `.psd1`. In PowerShell
   7.4+, `Start-ThreadJob` is an inbox cmdlet; listing the module breaks import.
5. **Never** surface exception detail (stack traces, tokens, credential
   fragments) in UI return values. Catch blocks return fixed, sanitised strings.
6. **Never** log fields classified `credential` (`cloud_session.client_secret`,
   `cloud_session.token`) — these are absolute, overriding any OBSERVABILITY
   declaration.
7. **PII** fields (`entra_user.mail`, `entra_user.upn`, `local_user.name`,
   `ad_user.samaccountname`) must not be written to `Write-Warning` via the
   default `$_` expansion — scrub first.
8. **CALLS boundaries are exclusive.** UI may call CORE / CLOUD / STATE. CORE
   and CLOUD may call STATE only. STATE calls nothing. Any other cross-layer
   call is a contract violation.

## Architectural norms

- **One private function per file** in `LazyWinAdminModule/Private/*.ps1`.
- **One public function** in `LazyWinAdminModule/Public/` — the entry point
  `Start-LazyWinAdmin`.
- **Module file size**: 800-line soft cap per file. `Start-LazyWinAdmin.ps1`
  currently exceeds this and is a known refactor target.
- **CIM session pattern**: `New-CimSession` in `try`, `Remove-CimSession` in
  `finally`. For `$ComputerName -iin @('localhost','127.0.0.1',$env:COMPUTERNAME)`,
  omit `-ComputerName` entirely (WinRM is not required for local CIM).
- **Async pattern**: `Start-ThreadJob` → `Register-ObjectEvent` → enqueue into
  `$state.SyncHash.UIQueue` (a `ConcurrentQueue`) → drained by a
  `DispatcherTimer` tick on the UI thread. Never call `Dispatcher.InvokeAsync`
  from background runspaces.

## Naming (VOCABULARY)

Use these canonical names; alternates are contract violations:
- `ComputerName` (not `target`, `hostname`, `machineName`)
- `CimSession` (not `wmi_session`, `cim_conn`)
- `CloudSession`, `GraphContext`, `AzContext`
- `SyncHash`, `AppState`, `RunspacePool`
- `RegistryHive`, `RegistryPath`, `RegistryValueName`, `RegistryValueData`
- `EntraFilter`, `IntuneFilter`, `AdFilter`
- `TenantId`, `ClientId`
- `InitializationScript`, `OnCompleted`

Full list: `lazywinadmin.speq` → `VOCABULARY` section.

## Input validation at boundaries

- `EntraFilter` / `IntuneFilter` — whitelist `[a-zA-Z0-9\s\-\.\@_]` then feed
  into Graph OData `$filter`. Single quotes **must** be blocked.
- `AdFilter` — whitelist for LDAP filter chars. Current whitelist rejects
  `'` (correct) but also rejects `$`, `(`, `)` which are legitimate in AD
  names (`PC01$`). Either broaden the whitelist or switch to the
  `Get-ADComputer -Filter { Name -like $AdFilter }` ScriptBlock form.
- `RegistryHive` — `[ValidateSet('HKLM','HKCU','HKU','HKCR')]`.
- `KeyPath` — validate length, not content (StdRegProv rejects malformed).

## Tests

- Pester v5 `Describe` / `Context` / `It` structure, Arrange-Act-Assert inside
  each `It`.
- New private function → add a `Context` in `Functions.Tests.ps1` with:
  happy path, error path, parameter validation, local-vs-remote routing.
- Prefer behavioural asserts over structural ones. "Function exists" tests
  belong in `Integrity.Tests.ps1` only.
- CI runs the full suite on `windows-latest`. Tests must not require WinRM,
  RSAT, or a live cloud tenant — mock the cmdlets.

## PR hygiene

- Update `README.md` when a feature or milestone ships.
- Update `state_lazywinadmin.speq` when an entity or flow changes status
  (PENDING → PARTIAL → BUILT).
- Commit messages: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`,
  `perf:`, `ci:`.
- PR title ≤ 70 chars; details in the body.
