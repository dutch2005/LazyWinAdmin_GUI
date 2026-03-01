# Project Status — mike-maze-it-adventures

**Last updated: 2026-03-01 (session 2)**

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

---

## ⏳ Requires Manual Action (cannot be done from code)

### 1. Deploy Supabase Edge Functions
Both edge functions are written and committed but NOT deployed to Supabase cloud.

```bash
npx supabase login
npx supabase link --project-ref <your-project-ref>
npx supabase functions deploy subscribe
npx supabase functions deploy unsubscribe
npx supabase secrets set RESEND_API_KEY=re_xxx
```

### 2. Apply DB Migration
The migration file exists at `supabase/migrations/20230101000000_newsletter_subscribers.sql`.
Either push via CLI or run directly in Supabase SQL Editor:

```sql
CREATE TABLE IF NOT EXISTS newsletter_subscribers (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  email text UNIQUE NOT NULL,
  unsubscribe_token uuid DEFAULT gen_random_uuid() NOT NULL,
  subscribed_at timestamptz DEFAULT now()
);
ALTER TABLE newsletter_subscribers ENABLE ROW LEVEL SECURITY;
```

### 3. Resend DNS Verification
For `newsletter@mikemaze.nl` to send mail:
- Sign up at resend.com, add domain `mikemaze.nl`
- Add SPF, DKIM, DMARC records to OVH DNS
- Verify domain in Resend dashboard
- Set secret: `npx supabase secrets set RESEND_API_KEY=re_xxx`

### 4. Publish Content Drafts
Three draft posts are in the `drafts/` folder. Publish via the admin panel at `/admin`:
- `drafts/tech/ai-automation-first-post.md`
- `drafts/personal/mycka-amalia.md`
- `drafts/gaming/cities-skylines-airsoft.md`

### 5. Verify OG Image Live
After deploy, confirm `https://mikemaze.nl/og-image.jpg` loads correctly.
Test with: https://developers.facebook.com/tools/debug/ or https://cards-dev.twitter.com/validator

---

## 🔮 Optional Future Improvements

- **Further bundle reduction**: Admin chunk is still 455KB (Tiptap is heavy). Could lazy-load Tiptap extensions individually.
- **Newsletter analytics**: Track open rates in Resend dashboard.
- **Comment system**: Add blog comments (Supabase table + UI component).
- **RSS feed**: Generate `public/feed.xml` alongside sitemap.
- **Image optimization**: `public/brand.png` is 1MB — could compress with `sharp`.
