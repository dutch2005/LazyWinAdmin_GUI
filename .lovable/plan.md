

# Fine-tune Light Mode Colors and Contrast

After reviewing all sections in light mode, here are the specific contrast and readability issues to fix, along with the solutions.

---

## Issues Found

1. **Category badge colors** (`text-green-400`, `text-blue-400`, `text-orange-400`) are too faint on white/light backgrounds — these need darker variants in light mode
2. **Terminal output** `text-green-400` in About and Contact section terminal blocks has poor contrast on the light secondary background
3. **Hero section** overlay (`bg-background/75`) makes the hero too washed-out in light mode — needs a lighter opacity or adjusted overlay
4. **Dot pattern** opacity is too subtle in light mode
5. **Blog post page** hardcoded `text-green-400` and `text-blue-400` category colors in `BlogPost.tsx` have same issue

---

## Changes

### `src/index.css`
- Add light-mode-aware utility classes for category colors that automatically switch between `-400` (dark) and `-600`/`-700` (light) variants
- Add a `.light .terminal-output` helper for green terminal text
- Adjust dot-pattern opacity for light mode

### `src/components/BlogSection.tsx`
- Replace hardcoded `text-green-400`/`text-blue-400`/`text-orange-400` in `categoryColors` with theme-aware classes using `dark:text-green-400 text-green-700` pattern

### `src/pages/BlogPost.tsx`
- Same category color fix as BlogSection
- Fix terminal-style green text in rendered content

### `src/components/AboutSection.tsx`
- Replace `text-green-400` on terminal output with a theme-aware class (`text-green-700 dark:text-green-400`)
- Fix the green "available" dot: `bg-green-400` → `bg-green-500 dark:bg-green-400`

### `src/components/ContactSection.tsx`
- Same terminal output green text fix
- Fix `text-green-400` on success checkmark icon

### `src/components/Hero.tsx`
- Change hero dark overlay from `bg-background/75` to `bg-background/80 dark:bg-background/75` for better light-mode contrast with the background image

### `src/components/CookieConsent.tsx`
- No changes needed — already using semantic tokens

### `src/components/Footer.tsx`
- No changes needed — already using semantic tokens

---

## Technical Details

The core strategy is replacing hardcoded Tailwind color utilities (e.g. `text-green-400`) with dark-mode-prefixed pairs (`text-green-700 dark:text-green-400`). This leverages the existing `darkMode: ["class"]` configuration in `tailwind.config.ts`.

Files modified: 5 (`BlogSection.tsx`, `BlogPost.tsx`, `AboutSection.tsx`, `ContactSection.tsx`, `Hero.tsx`, `index.css`)

No new dependencies. No database changes.

