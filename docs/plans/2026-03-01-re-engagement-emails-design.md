# Re-engagement Email System — Design

**Date:** 2026-03-01
**Status:** Approved

---

## Overview

Duolingo-style re-engagement emails for `mikemaze.nl` newsletter subscribers who haven't visited in a while. Emails escalate in personal tone over 5 intervals: 1 week, 1 month, 3 months, 6 months, 1 year. They feel written by a person, not a system.

---

## Database Schema

```sql
-- On newsletter_subscribers
ALTER TABLE newsletter_subscribers ADD COLUMN last_visit_at timestamptz;
ALTER TABLE newsletter_subscribers ADD COLUMN last_email_open_at timestamptz;
ALTER TABLE newsletter_subscribers ADD COLUMN last_active_at timestamptz
  GENERATED ALWAYS AS (GREATEST(last_visit_at, last_email_open_at, created_at)) STORED;
ALTER TABLE newsletter_subscribers ADD COLUMN reminders_sent jsonb DEFAULT '[]';
-- reminders_sent example: ["1w", "1m"]

-- Reminder audit log
CREATE TABLE reminder_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subscriber_id uuid REFERENCES newsletter_subscribers(id) ON DELETE CASCADE,
  interval text NOT NULL,  -- '1w' | '1m' | '3m' | '6m' | '1y'
  sent_at timestamptz DEFAULT now()
);
```

`last_active_at` is a generated column — always the most recent of visit, email open, or signup.

---

## Tracking Architecture

### Email Open Tracking (Pixel)
Every outgoing email (welcome + all reminders) contains a 1×1 transparent tracking pixel:
```html
<img src="https://ppmhntfohxjcqyzfbpui.supabase.co/functions/v1/track-open?t=<unsubscribe_token>"
     width="1" height="1" style="display:none" />
```
When an email client loads it → `track-open` edge function → sets `last_email_open_at = now()`.

### Site Visit Tracking (URL Token + JS Beacon)
All email links to mikemaze.nl include `?ut=<unsubscribe_token>`:
```
https://mikemaze.nl/blog/some-post?ut=abc123
```
On page load, `Index.tsx` and `BlogPost.tsx`:
1. Check URL for `?ut=` param
2. Store token in `localStorage` if found
3. If token in localStorage, POST to `track-visit` edge function → sets `last_visit_at = now()`
4. Token persists — direct visits after initial click-through are also tracked

### Edge Functions
- `track-open` — GET, no auth (token is the identifier), updates `last_email_open_at`
- `track-visit` — POST, no auth, updates `last_visit_at`

---

## send-reminders Edge Function

Triggered daily at 09:00 UTC via pg_cron. For each subscriber:

1. Calculate `days_inactive = now() - last_active_at`
2. Determine interval bucket:

| Interval | Days Range | Tone |
|----------|-----------|------|
| `1w` | 7–8 days | Casual ping |
| `1m` | 30–32 days | Friendly check-in |
| `3m` | 90–93 days | Warmer, more personal |
| `6m` | 180–185 days | Genuine "miss you" |
| `1y` | 365–370 days | Funny, self-aware |

3. Skip if interval already in `reminders_sent`
4. Send via Resend → append interval to `reminders_sent` → insert into `reminder_log`

### pg_cron Setup
```sql
SELECT cron.schedule(
  'daily-re-engagement',
  '0 9 * * *',
  $$SELECT net.http_post(
    url := 'https://ppmhntfohxjcqyzfbpui.supabase.co/functions/v1/send-reminders',
    headers := '{"Authorization":"Bearer <SERVICE_ROLE_KEY>"}'::jsonb,
    body := '{}'::jsonb
  )$$
);
```

---

## Email Templates

All emails: signed "Mike", include tracking pixel, all links use `?ut=<token>`, unsubscribe link at bottom.

### 1 Week — Casual ping
- **Subject:** `hey, still there?`
- **Body:** Short, lowercase, checks if welcome email landed in spam. References recent posts. Feels like a Slack message.

### 1 Month — Friendly check-in
- **Subject:** `a month already? here's what you missed`
- **Body:** References AI automation and developer tools content. Invites them back with a specific post.

### 3 Months — Warmer, more personal
- **Subject:** `checking in on you`
- **Body:** Asks what kind of content would bring them back. Invites a reply. Links to best post of the quarter.

### 6 Months — Genuine, honest
- **Subject:** `honestly? I miss having you around`
- **Body:** Honest acknowledgment of the gap. No pressure. Open door.

### 1 Year — Self-aware, funny
- **Subject:** `ok it's been a whole year. I had to say something.`
- **Body:** Self-deprecating, acknowledges the absurdity, still warm. Clear unsubscribe option.

---

## Error Handling

- `track-open` / `track-visit`: silent fail (never show errors to users, always return 200)
- `send-reminders`: per-subscriber try/catch — one failure doesn't stop others; log errors per subscriber
- Reminder deduplication: `reminders_sent` jsonb array prevents double-sends even if cron fires twice

---

## Files to Create/Modify

| File | Change |
|------|--------|
| `supabase/migrations/20260301010000_re_engagement_schema.sql` | New schema |
| `supabase/functions/track-open/index.ts` | New edge function |
| `supabase/functions/track-visit/index.ts` | New edge function |
| `supabase/functions/send-reminders/index.ts` | New edge function |
| `supabase/functions/subscribe/index.ts` | Add pixel + `?ut=` to welcome email |
| `src/pages/Index.tsx` | JS beacon on page load |
| `src/pages/BlogPost.tsx` | JS beacon on page load |
