```markdown
# LazyWinAdmin_GUI Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill teaches the core development conventions and workflows used in the `LazyWinAdmin_GUI` TypeScript project. It covers file and code style, commit patterns, testing practices, and the main maintenance workflows for code quality, testing, and release management. While the repository is primarily TypeScript, it also contains PowerShell modules and scripts, with a focus on automation and CI/CD best practices.

## Coding Conventions

### File Naming
- Use **kebab-case** for all file names.
  - Example: `main-window.ts`, `user-settings.test.ts`

### Import Style
- Use **relative imports** for all modules.
  - Example:
    ```typescript
    import { getUserSettings } from './user-settings';
    ```

### Export Style
- Use **named exports**.
  - Example:
    ```typescript
    // In user-settings.ts
    export function getUserSettings() { ... }
    export function setUserSettings() { ... }
    ```

### Commit Messages
- Follow **conventional commit** patterns.
  - Prefixes: `fix:`, `test:`, `chore:`
  - Example: `fix: handle null user input in settings dialog`

## Workflows

### Add or Improve Private Function Tests
**Trigger:** When you want to increase test coverage for private PowerShell functions or add tests for new/refactored private code.  
**Command:** `/add-private-function-tests`

1. Create one or more new `*.Tests.ps1` files in `LazyWinAdminModule/Tests/` for each private function.
2. Update `Run-Tests.ps1` to ensure new tests are discovered and run.
3. Optionally, fix minor issues in the corresponding private function implementation.

**Example:**
```powershell
# LazyWinAdminModule/Tests/Get-Secret.Tests.ps1
Describe "Get-Secret private function" {
    It "returns the expected secret" {
        # test logic here
    }
}
```

### Tighten Linting and CI Configuration
**Trigger:** When you want to enforce stricter linting or CI standards, or resolve existing linter warnings.  
**Command:** `/tighten-linting`

1. Update or add `PSScriptAnalyzerSettings.psd1` with stricter rules.
2. Fix all `.ps1`/`.psd1` files to comply with the new rules (e.g., encoding, code style, error handling).
3. Update or add `.github/workflows/ci.yml` to reflect new lint/test steps.
4. Optionally, update test files to suppress or fix linter warnings.

**Example:**
```powershell
# PSScriptAnalyzerSettings.psd1
@{
    Rules = @{
        PSUseConsistentIndentation = @{
            Enable = $true
        }
    }
}
```

### Release Version Bump and README Update
**Trigger:** When you want to publish a new release or document recent changes.  
**Command:** `/release-bump`

1. Update `ModuleVersion` in `LazyWinAdminModule.psd1`.
2. Update `PSScriptAnalyzerSettings.psd1` or other config files if CI/lint settings change.
3. Edit `README.md` to add version history, update test counts, and document new features or changes.

**Example:**
```powershell
# LazyWinAdminModule.psd1
ModuleVersion = '1.2.3'
```

## Testing Patterns

- **Test files** are named using the pattern `*.test.ts` for TypeScript and `*.Tests.ps1` for PowerShell.
- The TypeScript test framework is **unknown**, but tests are colocated with source files or in a dedicated test directory.
- PowerShell tests use **Pester v5** and are discovered via `Run-Tests.ps1`.

**Example:**
```typescript
// user-settings.test.ts
import { getUserSettings } from './user-settings';

test('returns default settings', () => {
  expect(getUserSettings()).toEqual({ theme: 'light' });
});
```

## Commands

| Command                        | Purpose                                                         |
|--------------------------------|-----------------------------------------------------------------|
| /add-private-function-tests     | Add or improve tests for private PowerShell functions           |
| /tighten-linting               | Enforce stricter linting and CI configuration                   |
| /release-bump                  | Bump module version and update README for a new release         |
```
