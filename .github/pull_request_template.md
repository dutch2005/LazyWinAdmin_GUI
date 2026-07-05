<!--
  Fill in each section. The AI reviewers (Gemini Code Assist, Kilo Code,
  CodeRabbit) read this body to understand intent — an empty template gets
  a shallower review.
-->

## Summary
<!-- 2-3 sentences. What changed, why now. Not a file list. -->

## Changes
<!-- Bullet list of the high-level diff narrative. Mention new/removed
     Private functions, new XAML controls, new private-function seams. -->

## Test plan
<!--
  Markdown checklist. Include the Pester run output at minimum.
  Example:
    - [x] `pwsh -NoProfile -File ./LazyWinAdminModule/Tests/Run-Tests.ps1` → 228 passed, 0 failed
    - [x] Manual: Start-LazyWinAdmin opens; Services tab Start/Stop works
    - [ ] N/A: Exchange tab (ExchangeOnlineManagement not installed in this env)
-->
- [ ] Pester suite green (`Run-Tests.ps1`)
- [ ] PSScriptAnalyzer: no new errors
- [ ] Manual GUI sanity check on the affected tab(s)

## Risks & rollback
<!--
  Single most useful field during an on-call rollback. Name the blast radius.
  "Reversible via `git revert`" is the default. Call out anything else:
    - Changes registry write path → requires re-running …
    - Bumps PowerShellVersion minimum → users must upgrade pwsh
    - Breaks v1.2 → v1.3 migration of X
-->

## `.speq` compliance
<!-- Delete this section if the change is trivial (typo / docs). -->
- [ ] No new `VOCABULARY` violations (canonical names used)
- [ ] No `CALLS` boundary crossings (UI → CORE/CLOUD/STATE only; CORE/CLOUD → STATE only)
- [ ] `CLASSIFY` fields not logged / exposed (`credential`, `pii`, `sensitive`)
- [ ] `state_lazywinadmin.speq` updated if an entity/flow changed status

## Linked issue
<!-- Closes #N / Fixes #N / Resolves #N — never close manually. -->
Closes #
