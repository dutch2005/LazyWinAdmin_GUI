# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
npm run dev        # Start dev server at http://localhost:8080 (not 5173)
npm run build      # Production build
npm run preview    # Preview production build
npm run lint       # ESLint (flat config)
npm test           # Run tests once (Vitest)
npm run test:watch # Run tests in watch mode
```

Run a single test file: `npx vitest run src/test/example.test.ts`

## Environment Variables

Create `.env` in project root:
```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=your-anon-key
```

## Architecture

**React 19 SPA** (Vite + SWC) deployed via Lovable on every push to `main`.

### Provider hierarchy (`App.tsx`)
`HelmetProvider` → `QueryClientProvider` → `TooltipProvider` → `LanguageProvider` → `ThemeProvider` → `BrowserRouter`

### Routes
| Path | Component | Notes |
|------|-----------|-------|
| `/` | `Index.tsx` | Homepage with all sections |
| `/blog/:slug` | `BlogPost.tsx` | Fetches post from Supabase by slug |
| `/admin` | `Admin.tsx` | Protected; requires Supabase auth + `admin` role in `user_roles` table |
| `/admin/login` | `AdminLogin.tsx` | |

### Internationalisation
`LanguageContext` (`src/contexts/LanguageContext.tsx`) provides `{ lang, setLang, t }`. Default language is `nl`. All translation strings are defined inline in that file (no external i18n library).

Blog posts store bilingual content in separate Supabase columns: `title_nl`/`title_en`, `content_nl`/`content_en`, `excerpt_nl`/`excerpt_en`. When a language version is missing, the other language falls back and a banner is shown to the user.

### Data layer
- **Supabase client**: `src/lib/supabaseClient.ts` exports `db` (the Supabase client). The generated types live in `src/integrations/supabase/types.ts`.
- **TanStack Query** is available globally but direct `useEffect` + Supabase calls are also used in page-level components.
- **Key Supabase tables**: `blog_posts`, `contact_messages`, `newsletter_subscribers`, `user_roles`, `admin_audit_log`.

### Blog post content rendering
Posts can contain either **Markdown** or **HTML** (from Tiptap editor). `isHtmlContent()` in `src/lib/markdownToHtml.ts` detects which format by checking if content starts with `<`. HTML content is sanitised with **DOMPurify** before `dangerouslySetInnerHTML`. Markdown is parsed by a custom `markdownToHtml()` utility in the same file.

### Admin panel
`Admin.tsx` checks Supabase session and `user_roles` table on every load; unauthenticated or non-admin users are redirected to `/admin/login`. The panel is tab-based, switching between panels via `renderPanel()`.

### Path alias
`@/` resolves to `src/` (configured in both `vite.config.ts` and `vitest.config.ts`).

### Workflow protocol
Before implementing non-trivial features or refactors, follow the Superpowers protocol (from `.cursorrules`):
1. **Brainstorm** — explore ideas
2. **Write Plan** — create step-by-step plan
3. **Execute Plan** — build code from approved plan
4. **Review** — check code quality
