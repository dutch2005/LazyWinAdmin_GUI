# Code Review — LazyWinAdmin GUI v1.3.0

**Date:** 2026-04-24
**Reviewers:** Claude Opus 4.7 (primary), `code-reviewer` sub-agent (structural),
`security-reviewer` sub-agent (security)
**Baseline:** 228 Pester tests, 0 failures, 0 skipped (68.5s). Strict mode on.
`Invoke-Pester` via `LazyWinAdminModule/Tests/Run-Tests.ps1`.

## Executive summary

The module is in good structural shape: the WPF-module layout, async
dispatch pattern (`Start-ThreadJob` → `ConcurrentQueue` → `DispatcherTimer`),
and the explicit `.speq` contract are all healthy. Security-critical inputs
(EntraFilter, IntuneFilter) are whitelisted, credentials are handled as
`SecureString`, and the Exchange/Graph auth boundaries do not leak tokens
into UI output.

Eleven findings surfaced across two review passes. **Two are blocking**
(1 security, 1 project-rule violation), **five are high-impact**, and the
rest are maintenance traps. None of the findings reflect a broken feature;
they represent residual risk and code-smell debt accumulated during the
rapid v1.1 → v1.3 progression.

---

## Blocking findings (fix before next merge)

### 🚨 SEC-1 — Path traversal in Intune script download
**File:** [LazyWinAdminModule/Private/Get-IntuneManagementScript.ps1:55](LazyWinAdminModule/Private/Get-IntuneManagementScript.ps1)
**Severity:** CRITICAL
```powershell
$filePath = Join-Path $DownloadPath $detail.fileName
```
`$detail.fileName` comes from the Graph API response — external, untrusted.
`Join-Path "C:\scripts" "..\..\Windows\System32\evil.ps1"` resolves **outside**
`$DownloadPath`. Worse, an absolute second argument (`Join-Path "C:\a" "C:\b"`)
returns `C:\b` on Windows — no validation, no warning.

**Fix:**
```powershell
$safeName = [System.IO.Path]::GetFileName($detail.fileName)
if ($safeName -notmatch '^[\w\-. ]+\.ps1$') {
    Write-Warning "Skipping script with unsafe fileName: $($detail.fileName)"
    continue
}
$filePath = Join-Path $DownloadPath $safeName
```
Effort: 10 minutes + one Pester test with a malicious fixture.

### 🚨 RULE-1 — `Get-WmiObject` in production code
**File:** [LazyWinAdminModule/Private/Get-DeviceComplianceStatus.ps1:86](LazyWinAdminModule/Private/Get-DeviceComplianceStatus.ps1)
**Severity:** CRITICAL (hard project rule)
```powershell
$uwf = Get-WmiObject -Namespace 'root\standardcimv2\embedded' -Class 'UWF_Filter' -ErrorAction SilentlyContinue
```
CLAUDE.md explicitly forbids `Get-WmiObject`. The `.speq` CORE layer declares
`NEVER use-get-wmiobject`. The rest of the file correctly uses
`Get-CimInstance`; this is the only outlier.

**Fix (one-line):**
```powershell
$uwf = Get-CimInstance -Namespace 'root\standardcimv2\embedded' -ClassName 'UWF_Filter' -ErrorAction SilentlyContinue
```
Effort: 2 minutes + existing Pester test adjustment.

---

## High-impact findings

### SEC-2 — AD `-Filter` string interpolation
**File:** [LazyWinAdminModule/Private/Get-ComputerADInfo.ps1:41-43, 52-53, 64-65](LazyWinAdminModule/Private/Get-ComputerADInfo.ps1)
```powershell
$ldapFilter = if ($AdFilter) { "Name -like '$AdFilter'" } ...
Get-ADComputer -Filter $ldapFilter
```
`-Filter` on AD cmdlets is a PowerShell expression string, not an LDAP filter.
The `'` single-quote whitelist blocks the most obvious injection, but Unicode
homoglyphs or any whitelist relaxation would re-open the hole.

**Fix:** use the ScriptBlock `-Filter` form, which is parameterised:
```powershell
Get-ADComputer -Filter { Name -like $AdFilter } -Properties ...
```
Apply to all three switch branches (Computer/User/Group).

### STRUCT-1 — `Start-LazyWinAdmin.ps1` is 1 090 lines
**File:** [LazyWinAdminModule/Public/Start-LazyWinAdmin.ps1](LazyWinAdminModule/Public/Start-LazyWinAdmin.ps1) (54 KB)
Exceeds the 800-line project cap. Mixes XAML load, control discovery, async
infrastructure, and 50+ tab handlers.

**Proposed split:**
```
LazyWinAdminModule/
├── Public/
│   └── Start-LazyWinAdmin.ps1        # ~150 lines: XAML load, dot-source, ShowDialog()
├── Helpers/
│   └── Invoke-AsyncAction.ps1        # async dispatch + SetBusy + AppendOutput
└── Handlers/
    ├── SystemTab.ps1                 # ping, uptime, RDP, hardware, network
    ├── ServicesTab.ps1               # list, filter, start/stop/restart, export
    ├── SoftwareTab.ps1
    ├── IdentityTab.ps1               # local users/groups + Entra
    ├── CloudTab.ps1                  # Graph/Az auth, Intune, Azure, scripts
    ├── ComplianceTab.ps1
    ├── ExchangeTab.ps1
    ├── RegistryTab.ps1
    └── AdTab.ps1
```
Each handler file captures closure over `$window`, `$state`, `$PrivatePath`,
and the UI-helper scriptblocks — works inside the same runspace.
Effort: 4–6 hours, best done as one atomic PR with no other changes so the
diff is reviewable.

### STRUCT-2 — Dead duplicate registry helper
**File:** [LazyWinAdminModule/Private/Get-ComputerRegistryValue.ps1](LazyWinAdminModule/Private/Get-ComputerRegistryValue.ps1)
Orphan function. No UI handler calls it (all three registry buttons dispatch
to `Invoke-ComputerRegistry`). Always passes `-ComputerName` even for
localhost — reintroduces the WinRM dependency that v1.2.0 fixed. Strict
subset of `Invoke-ComputerRegistry` except for `HKCC` support.

**Proposed action:** delete the file. Add `HKCC` to `Invoke-ComputerRegistry`'s
`ValidateSet` only if a concrete use-case exists. Add an `Integrity` test
asserting the file is gone to prevent re-introduction.

### STRUCT-3 — Missing CIM-session guards in three helpers
**Files:** [Get-ComputerService.ps1:33](LazyWinAdminModule/Private/Get-ComputerService.ps1),
[Get-ComputerLocalUser.ps1:17](LazyWinAdminModule/Private/Get-ComputerLocalUser.ps1),
[Get-ComputerLocalGroup.ps1:14](LazyWinAdminModule/Private/Get-ComputerLocalGroup.ps1)

Pass `-ComputerName` to `Get-CimInstance` directly, without `New-CimSession` +
`try/finally`. On failure the DCOM/WSMan transport may leak. Inconsistent
with `Get-ComputerHardware`, `Get-ComputerNetwork`, `Set-ComputerRDP` which
do it correctly.

**Proposed fix:** extract a single helper:
```powershell
# LazyWinAdminModule/Private/New-LocalOrRemoteCimSession.ps1
function New-LocalOrRemoteCimSession {
    param([string]$ComputerName)
    $isLocal = $ComputerName -iin @('localhost','127.0.0.1',$env:COMPUTERNAME)
    if ($isLocal) { New-CimSession } else { New-CimSession -ComputerName $ComputerName }
}
```
Every CIM helper then opens via this function. The `$isLocal` check is
currently inlined ~10 times across `Private/*.ps1` — this is the natural
consolidation seam and, as a bonus, the single place where the future
`$state.CimSessions` cache reuse can be wired in.

---

## Medium findings

### SEC-3 — PII (`UPN`) in `Write-Warning $_`
**Files:** [Get-EntraIdentity.ps1:52](LazyWinAdminModule/Private/Get-EntraIdentity.ps1),
[Get-IntuneDevice.ps1:38](LazyWinAdminModule/Private/Get-IntuneDevice.ps1)

`Write-Warning "... $_"` expands the full exception including the OData
filter that contains the user-typed UPN. `entra_user.upn` is `.speq`
`CLASSIFY: pii`.

**Fix:** log only the exception type + a fixed message.
```powershell
catch { Write-Warning "Error querying Entra ID ($($_.Exception.GetType().Name)): query failed" }
```

### SEC-4 — UPN written raw to UI output box
**File:** [Start-LazyWinAdmin.ps1:908](LazyWinAdminModule/Public/Start-LazyWinAdmin.ps1)
The Exchange tab writes `"No shared mailbox permissions found for $upn."` to
`txtOutput`. If that window is screenshotted or copied, PII leaks.
**Fix:** replace with `"No shared mailbox permissions found."` — the user
already knows which UPN they queried.

### SEC-5 — AD Group query returns `SamAccountName`
**File:** [Get-ComputerADInfo.ps1:69](LazyWinAdminModule/Private/Get-ComputerADInfo.ps1)
The User branch explicitly omits it (line 55 comment). The Group branch
includes it. Not strictly the same type, but the `.speq` rule
`ad_user.samaccountname NEVER logged` is ambiguous about groups — either
update the spec or drop the field.

### STRUCT-4 — `CimSessions` cache is dead infrastructure
**File:** [ApplicationState.ps1:29](LazyWinAdminModule/Classes/ApplicationState.ps1)
Declared, initialised, has `EvictCimSession` method — but never written to
by any private function. Matches `state_lazywinadmin.speq` declaration
`cim_session PARTIAL`. Either wire the cache (via STRUCT-3's
`New-LocalOrRemoteCimSession` helper) or remove the field.

### STRUCT-5 — Dynamic method-name construction in `Invoke-ComputerRegistry`
**File:** [Invoke-ComputerRegistry.ps1:~62](LazyWinAdminModule/Private/Invoke-ComputerRegistry.ps1)
```powershell
$methodName = "Set$($ValueType)Value"
```
`$ValueType` is `[ValidateSet]`-constrained today, but the pattern invites a
future refactor to break validation. Safer: explicit `switch` mapping each
enum value to a literal method name.

### VALID-1 — `AdFilter` whitelist too narrow
**File:** [Get-ComputerADInfo.ps1:34](LazyWinAdminModule/Private/Get-ComputerADInfo.ps1)
Current regex `[^a-zA-Z0-9\s\-\.\@_\*]` rejects `PC01$` (computer account
convention), `O'Brien` (apostrophe in surnames), and parenthesised OUs.
Users searching for common names get a silent `$null` + vague warning.
**Fix:** once SEC-2 is applied (ScriptBlock `-Filter`), injection is no
longer a concern and the whitelist can expand — or be replaced with a
length cap only.

---

## Low findings

### BUG-1 — `Test-ComputerPort` ignores `$waitResult`
**File:** [Test-ComputerPort.ps1:19-24](LazyWinAdminModule/Private/Test-ComputerPort.ps1)
Stores the `AsyncWaitHandle.WaitOne` boolean but never checks it before
calling `$tcpClient.Connected`. Race window on slow or firewalled targets.
Not user-visible today, but a latent incorrect-state trap.

### SEC-6 — DN fragment in `Write-Warning $_`
**File:** [Get-ComputerADInfo.ps1:74](LazyWinAdminModule/Private/Get-ComputerADInfo.ps1)
Same pattern as SEC-3. `ad_user.distinguishedname` is `.speq`
`CLASSIFY: internal`.

---

## `.speq` compliance audit

| Entity / Flow | State file | Code reality | Delta |
|---|---|---|---|
| `cim_session` | PARTIAL | Cache declared, never used | Matches |
| `ad_computer`, `ad_user`, `ad_group` | PENDING | Code **exists and works** (`Get-ComputerADInfo.ps1`) | **State stale** — bump to BUILT once SEC-2 + VALID-1 land |
| `ad_lookup` flow | PENDING | Registered in `Get-ComputerADInfo` | **State stale** — same |
| `computer` | PARTIAL | ping/uptime/rdp done; AD integration not wired into UI tab | Matches |

Recommend: run `speq state set ad_computer BUILT` et al. after the security
fixes land, to reflect that the code path is present.

---

## Test-quality observations

- **228 passing tests** with meaningful mocks — good baseline.
- **`Integrity.Tests.ps1`** is mostly existence assertions. Useful as a
  structural safety net but low signal for behaviour regressions.
- **`Get-DeviceComplianceStatus` and `Set-DeviceComplianceItem` have zero
  coverage** in `Functions.Tests.ps1`. These are registry-write functions;
  `Get-ItemProperty` / `Set-ItemProperty` mock easily.
- **`AdFilter` validation** (currently on line 34 of `Get-ComputerADInfo`)
  has no dedicated test. Given it is a security-adjacent input filter,
  it warrants explicit assertions for known-bad and known-good edge cases.
- **`Get-IntuneManagementScript`** (the path-traversal host) has no
  coverage. A fixture `$detail.fileName = '../../evil.ps1'` assertion is
  the canonical regression test for SEC-1.

---

## AI reviewer onboarding

This PR wires in three AI reviewers. Two need per-repo install, one is
purely config.

### Gemini Code Assist — GitHub App
1. Install: **<https://github.com/apps/gemini-code-assist>** → grant access
   to this repository.
2. Config file **already added**: [.gemini/config.yaml](.gemini/config.yaml).
3. Style rules **already added**: [.gemini/styleguide.md](.gemini/styleguide.md)
   — this is the file Gemini quotes when it flags a violation, so keep it
   authoritative.
4. Interact in PR comments: `/gemini review`, `/gemini summary`, `/gemini help`.

### Kilo Code — GitHub App
1. Install the Kilo Code Bot: **<https://github.com/apps/kilo-code-bot>**
2. Enable AI Code Review in the Kilo dashboard:
   - Sign in at **<https://kilo.ai>** (paid / free-tier per their pricing)
   - Integrations → GitHub → connect
   - Review Agent tab → toggle **Enable AI Code Review**
   - Choose repositories → select this repo
3. Kilo Code is **dashboard-configured** — no repo file. Per-repo prompts
   can be authored in the dashboard; keep them aligned with
   [`.gemini/styleguide.md`](.gemini/styleguide.md) for consistency.

### CodeRabbit — GitHub App (fallback / companion)
1. Install: **<https://github.com/apps/coderabbitai>**
2. Config **already added**: [.coderabbit.yaml](.coderabbit.yaml).
3. Path-specific instructions already encoded for `Public/`, `Private/`,
   `Tests/`, and `lazywinadmin.speq`.

Having three different models means their blind-spots are unlikely to
overlap — exactly the multi-model second-opinion pattern called for in the
user's global review guidance.

### CI / permissions considerations

- [.github/workflows/ci.yml](.github/workflows/ci.yml) runs PSScriptAnalyzer
  + Pester v5 on `windows-latest` with `permissions: contents: read` — the
  minimum needed. AI reviewers use their own app tokens, not the workflow
  `GITHUB_TOKEN`, so no extra permission grants are required.
- **Branch protection**: once the CI workflow has its first successful run,
  add `CI / PSScriptAnalyzer` and `CI / Pester v5` as required status
  checks on `master`. This prevents merges that break the build while
  still allowing AI reviewer comments (they are not status checks).
- **First-time-contributor workflow approval**: if the AI bots ever open
  auto-fix PRs (Kilo Code can, with dashboard config), the repo's
  *Actions → General → Fork pull request workflows* setting controls
  whether CI runs automatically. Default behaviour is safe.

---

## Prioritised action list

| # | Item | Severity | Effort |
|---|------|----------|--------|
| 1 | Replace `Get-WmiObject` with `Get-CimInstance` (RULE-1) | CRITICAL | 2 min |
| 2 | Sanitise `$detail.fileName` in Intune download (SEC-1) | CRITICAL | 10 min |
| 3 | Switch AD `-Filter` to ScriptBlock form (SEC-2) | HIGH | 30 min |
| 4 | Scrub `$_` in Entra/Intune/AD `Write-Warning` (SEC-3, SEC-6) | MEDIUM | 15 min |
| 5 | Drop UPN from `txtOutput` message (SEC-4) | MEDIUM | 5 min |
| 6 | Delete `Get-ComputerRegistryValue.ps1` (STRUCT-2) | HIGH | 15 min + test |
| 7 | Extract `New-LocalOrRemoteCimSession` helper + wire missing guards (STRUCT-3) | HIGH | 2–3 h |
| 8 | Split `Start-LazyWinAdmin.ps1` into tab handlers (STRUCT-1) | HIGH | 4–6 h |
| 9 | Decide cache fate: wire or drop (STRUCT-4) | MEDIUM | follows #7 |
| 10 | Add tests for `Get-IntuneManagementScript`, `Get-DeviceComplianceStatus`, `Set-DeviceComplianceItem`, `AdFilter` validation | MEDIUM | 2 h |
| 11 | Broaden `AdFilter` whitelist after SEC-2 lands (VALID-1) | LOW | 10 min |
| 12 | Fix `$waitResult` check in `Test-ComputerPort` (BUG-1) | LOW | 10 min |

Items 1–5 are individually small; they can ship as one security-fix PR.
Item 6 is a cleanup PR. Item 7 is a standalone refactor PR. Item 8 should
be its own PR — do not combine with behaviour changes.

---

## What is already good (do not regress)

- Async dispatch via `ConcurrentQueue` + `DispatcherTimer` — correct and
  robust. Flagged in Gemini/CodeRabbit configs to catch any reintroduction
  of `Dispatcher.InvokeAsync`.
- `SecureString` → `PSCredential` at the Graph boundary in
  `Connect-ModernCloud.ps1`. Clean.
- Registry CRUD via `StdRegProv` with `[ValidateSet]` on hive and value
  type. `Win32_Product` genuinely absent from software inventory.
- Module manifest correctly omits `ThreadJob` from `RequiredModules`
  (inbox in PS 7.4+).
- Pester v5 runner installs Pester on-demand if missing — works in a cold
  CI environment.
- `state_lazywinadmin.speq` matches code reality for everything except the
  AD entities and the `cim_session` cache (both flagged above).
