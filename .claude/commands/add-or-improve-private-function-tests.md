---
name: add-or-improve-private-function-tests
description: Workflow command scaffold for add-or-improve-private-function-tests in LazyWinAdmin_GUI.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /add-or-improve-private-function-tests

Use this workflow when working on **add-or-improve-private-function-tests** in `LazyWinAdmin_GUI`.

## Goal

Adds new Pester v5 test files for private PowerShell functions and updates the test runner to discover them, often alongside minor bugfixes in the target function.

## Common Files

- `LazyWinAdminModule/Tests/*.Tests.ps1`
- `LazyWinAdminModule/Tests/Run-Tests.ps1`
- `LazyWinAdminModule/Private/*.ps1`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Create one or more new *.Tests.ps1 files in LazyWinAdminModule/Tests/ for each private function.
- Update Run-Tests.ps1 to ensure new tests are discovered and run.
- Optionally, fix minor issues in the corresponding private function implementation.

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.