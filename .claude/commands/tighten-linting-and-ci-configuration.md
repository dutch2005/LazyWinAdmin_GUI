---
name: tighten-linting-and-ci-configuration
description: Workflow command scaffold for tighten-linting-and-ci-configuration in LazyWinAdmin_GUI.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /tighten-linting-and-ci-configuration

Use this workflow when working on **tighten-linting-and-ci-configuration** in `LazyWinAdmin_GUI`.

## Goal

Improves code quality by updating PSScriptAnalyzer settings, fixing lint warnings, and enhancing CI workflows.

## Common Files

- `LazyWinAdminModule/PSScriptAnalyzerSettings.psd1`
- `.github/workflows/ci.yml`
- `LazyWinAdminModule/**/*.ps1`
- `LazyWinAdminModule/**/*.psd1`
- `LazyWinAdminModule/Tests/*.ps1`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Update or add PSScriptAnalyzerSettings.psd1 with stricter rules.
- Fix all .ps1/.psd1 files to comply with the new rules (e.g., encoding, code style, error handling).
- Update or add .github/workflows/ci.yml to reflect new lint/test steps.
- Optionally, update test files to suppress or fix linter warnings.

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.