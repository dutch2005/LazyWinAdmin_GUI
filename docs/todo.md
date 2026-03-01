# Project Status — mike-maze-it-adventures

**Last updated: 2026-03-01 (session 3)**

---

## ✅ Completed

| Item | How |
|------|-----|
| Domain migration to mikemaze.nl | Manual — all SITE_URL constants fixed |
| OG image (`public/og-image.jpg`) | Generated via Gemini Imagen 4 Ultra |
| Brand PNG with glow animation | Generated, CSS `filter: drop-shadow` keyframe |
| Sitemap generation | `scripts/generate-sitemap.mjs`, runs on build |
| `robots.txt` sitemap reference | Updated |
| Social share buttons on BlogPost | LinkedIn, X, WhatsApp, Facebook, copy-link |
| Newsletter edge function (subscribe) | `supabase/functions/subscribe/index.ts` |
| Unsubscribe edge function + page | `supabase/functions/unsubscribe/index.ts` + `/unsubscribe?token=` |
| Unsubscribe token in welcome email | subscribe fn selects token after insert, injects link |
| DB migration file | `supabase/migrations/20230101000000_newsletter_subscribers.sql` |
| Skimlinks GDPR fix | Injected via JS after consent in `CookieConsent.tsx` |
| Bundle splitting (manualChunks) | vendor / ui / supabase chunks |
| Lazy-load admin routes | Admin, AdminLogin, Unsubscribe → `React.lazy()` |
| Bundle size | Main: 932KB → 473KB gzip (289KB → 148KB) |
| Security vulnerabilities | 0 vulnerabilities (`npm audit`) |
| ESLint | 0 errors, 6 warnings (all acceptable) |
| Tests | 30/30 passing (5 test files) |
| Content drafts | `drafts/tech/`, `drafts/personal/`, `drafts/gaming/` |
| XSS fix in BlogPost | `DOMPurify.sanitize()` on all `dangerouslySetInnerHTML` |
| SEOHead useMemo | Structured data stringified once via `useMemo` |
| Unify Supabase client | All pages use `src/lib/supabaseClient.ts` |
| Supabase Edge Functions deployed | subscribe, unsubscribe, track-open, track-visit, send-reminders |
| Resend DNS verified | SPF/DKIM/DMARC for mikemaze.nl in Cloudflare |
| Welcome email end-to-end | Subscribe → Resend → inbox confirmed working |
| Re-engagement email system | track-open pixel, track-visit beacon, send-reminders + pg_cron |
| Re-engagement DB schema | last_visit_at, last_email_open_at, last_active_at (generated), reminders_sent, reminder_log |
| pg_cron daily job | Fires 09:00 UTC, authenticated via CRON_SECRET |
| GDPR-aware visit tracking | `useVisitTracking` hook — requires cookie_consent=granted |

---

## ⏳ Requires Manual Action (cannot be done from code)

### 1. Publish Content Drafts
Three draft posts are in the `drafts/` folder. Publish via the admin panel at `/admin`:
- `drafts/tech/ai-automation-first-post.md`
- `drafts/personal/mycka-amalia.md`
- `drafts/gaming/cities-skylines-airsoft.md`

### 2. Verify OG Image Live
After deploy, confirm `https://mikemaze.nl/og-image.jpg` loads correctly.
Test with: https://developers.facebook.com/tools/debug/ or https://cards-dev.twitter.com/validator

---

## 🔮 Optional Future Improvements

- **Further bundle reduction**: Admin chunk is still 455KB (Tiptap is heavy). Could lazy-load Tiptap extensions individually.
- **Newsletter analytics**: Track open rates in Resend dashboard.
- **Comment system**: Add blog comments (Supabase table + UI component).
- **RSS feed**: Generate `public/feed.xml` alongside sitemap.
- **Image optimization**: `public/brand.png` is 1MB — could compress with `sharp`.
