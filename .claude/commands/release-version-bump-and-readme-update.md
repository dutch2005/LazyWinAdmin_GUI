---
name: release-version-bump-and-readme-update
description: Workflow command scaffold for release-version-bump-and-readme-update in LazyWinAdmin_GUI.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /release-version-bump-and-readme-update

Use this workflow when working on **release-version-bump-and-readme-update** in `LazyWinAdmin_GUI`.

## Goal

Bumps the module version, updates the manifest and README with new version info, test counts, and notable changes.

## Common Files

- `LazyWinAdminModule/LazyWinAdminModule.psd1`
- `LazyWinAdminModule/PSScriptAnalyzerSettings.psd1`
- `README.md`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Update ModuleVersion in LazyWinAdminModule.psd1.
- Update PSScriptAnalyzerSettings.psd1 or other config files if CI/lint settings change.
- Edit README.md to add version history, update test counts, and document new features or changes.

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.