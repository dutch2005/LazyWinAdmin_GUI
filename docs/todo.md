# Remaining TODOs — mike-maze-it-adventures

**Last updated: 2026-03-01 01:37 UTC**

## High Priority

### 1. Deploy Supabase Edge Function
The `subscribe` edge function is written but NOT yet deployed to Supabase.
```bash
npx supabase functions deploy subscribe
npx supabase secrets set RESEND_API_KEY=re_xxx
```
- Also need to verify `newsletter@mikemaze.nl` is added as a verified sender in Resend

### 2. Fix GitHub Security Vulnerabilities
GitHub reported 13 vulnerabilities (5 high, 6 moderate, 2 low) after the deps upgrade.
```bash
npm audit
npm audit fix
# If needed: npm audit fix --force (careful - may break things)
```

### 3. Create OG Image at mikemaze.nl/og-image.jpg
The OG image `public/og-image.jpg` was generated locally and is in git.
Verify it's served correctly at `https://mikemaze.nl/og-image.jpg` after deploy.

## Medium Priority

### 4. Resend Email Sender Verification
- Domain `mikemaze.nl` needs to be verified in Resend
- Add DNS records (SPF, DKIM) for `newsletter@mikemaze.nl`
- Check Resend dashboard for required DNS records

### 5. Supabase: newsletter_subscribers Table
Verify the table exists with correct schema:
```sql
CREATE TABLE newsletter_subscribers (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  email text UNIQUE NOT NULL,
  subscribed_at timestamptz DEFAULT now()
);
-- RLS: edge function uses service role, so RLS can be enabled
```

### 6. Skimlinks Consent
Skimlinks affiliate script was identified as being outside consent flow.
Needs to be moved inside a cookie consent check (GDPR).

### 7. Large JS Bundle Warning
Build outputs 1.22 MB JS chunk (gzip: 372 KB). Could split with:
- Dynamic imports for admin pages (`/admin/*`)
- `build.rollupOptions.output.manualChunks` in `vite.config.ts`

## Low Priority

### 8. Content Strategy
- Write first post mixing tech + personal (AI topic)
- Add baby daughter Mycka Amalia mention for personal branding
- Add Cities Skylines 2 / Airsoft content

### 9. Newsletter Unsubscribe Link
The welcome email footer mentions "click the unsubscribe link" but no such link/endpoint exists yet.
Need: `supabase/functions/unsubscribe/index.ts` + a page at `/unsubscribe?token=xxx`

### 10. ESLint Check
ESLint upgraded to v10. Run `npm run lint` to check for config/rule issues.
