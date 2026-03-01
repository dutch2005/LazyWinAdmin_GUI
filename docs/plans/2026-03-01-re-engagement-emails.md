# Re-engagement Email System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Send personal, human-feeling re-engagement emails at 1w/1m/3m/6m/1y to inactive newsletter subscribers, with pixel + URL token tracking to measure real activity.

**Architecture:** Three new Supabase Edge Functions (track-open, track-visit, send-reminders) + a pg_cron daily job + frontend beacon in Index.tsx/BlogPost.tsx. Activity is tracked via email open pixel and `?ut=<token>` URL param stored in localStorage. A generated column `last_active_at` always reflects the most recent activity.

**Tech Stack:** Supabase Edge Functions (Deno), pg_cron, Resend API, React 19, TypeScript

**Supabase project:** `ppmhntfohxjcqyzfbpui`

---

### Task 1: Database Migration — re-engagement schema

**Files:**
- Create: `supabase/migrations/20260301010000_re_engagement_schema.sql`

**Step 1: Create the migration file**

```sql
-- supabase/migrations/20260301010000_re_engagement_schema.sql

-- Activity tracking columns on newsletter_subscribers
ALTER TABLE newsletter_subscribers
  ADD COLUMN IF NOT EXISTS last_visit_at timestamptz,
  ADD COLUMN IF NOT EXISTS last_email_open_at timestamptz,
  ADD COLUMN IF NOT EXISTS reminders_sent jsonb DEFAULT '[]';

-- Generated column: always the most recent activity
ALTER TABLE newsletter_subscribers
  ADD COLUMN IF NOT EXISTS last_active_at timestamptz
  GENERATED ALWAYS AS (
    GREATEST(
      COALESCE(last_visit_at, created_at),
      COALESCE(last_email_open_at, created_at),
      created_at
    )
  ) STORED;

-- Audit log for sent reminders
CREATE TABLE IF NOT EXISTS reminder_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subscriber_id uuid REFERENCES newsletter_subscribers(id) ON DELETE CASCADE,
  interval text NOT NULL CHECK (interval IN ('1w','1m','3m','6m','1y')),
  sent_at timestamptz DEFAULT now()
);
```

**Step 2: Apply via Management API**

```bash
TOKEN=$(grep MikeMaze_IT_ACL_TOKEN .env | cut -d'"' -f2)

curl -s -X POST "https://api.supabase.com/v1/projects/ppmhntfohxjcqyzfbpui/database/query" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"query\":\"$(sed 's/"/\\"/g' supabase/migrations/20260301010000_re_engagement_schema.sql | tr '\n' ' ')\"}" \
  -w "\nHTTP:%{http_code}"
```

Expected: `HTTP:201`

**Step 3: Verify columns exist**

```bash
source .env
curl -s "https://ppmhntfohxjcqyzfbpui.supabase.co/rest/v1/newsletter_subscribers?select=last_visit_at,last_email_open_at,last_active_at,reminders_sent&limit=1" \
  -H "apikey: $VITE_EXTERNAL_SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $VITE_EXTERNAL_SUPABASE_SERVICE_KEY"
```

Expected: JSON array (not error about missing columns)

**Step 4: Commit**

```bash
git add supabase/migrations/20260301010000_re_engagement_schema.sql
git commit -m "feat: add re-engagement tracking columns and reminder_log table"
```

---

### Task 2: track-open Edge Function

**Files:**
- Create: `supabase/functions/track-open/index.ts`

**Step 1: Create the function**

```typescript
// supabase/functions/track-open/index.ts
import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  // Always return a 1x1 transparent GIF — never error to the client
  const PIXEL = new Uint8Array([
    0x47,0x49,0x46,0x38,0x39,0x61,0x01,0x00,0x01,0x00,0x80,0x00,0x00,
    0xff,0xff,0xff,0x00,0x00,0x00,0x21,0xf9,0x04,0x00,0x00,0x00,0x00,
    0x00,0x2c,0x00,0x00,0x00,0x00,0x01,0x00,0x01,0x00,0x00,0x02,0x02,
    0x44,0x01,0x00,0x3b
  ]);
  const pixelResponse = () => new Response(PIXEL, {
    status: 200,
    headers: {
      "Content-Type": "image/gif",
      "Cache-Control": "no-store, no-cache, must-revalidate",
      "Pragma": "no-cache",
    },
  });

  try {
    const url = new URL(req.url);
    const token = url.searchParams.get("t");
    if (!token) return pixelResponse();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    await supabase
      .from("newsletter_subscribers")
      .update({ last_email_open_at: new Date().toISOString() })
      .eq("unsubscribe_token", token);
  } catch (e) {
    console.error("track-open error:", e);
  }

  return pixelResponse();
});
```

**Step 2: Deploy**

```bash
source .env
SUPABASE_ACCESS_TOKEN="$MikeMaze_IT_ACL_TOKEN" npx supabase functions deploy track-open --project-ref ppmhntfohxjcqyzfbpui
```

Expected: `Deployed Functions on project ppmhntfohxjcqyzfbpui: track-open`

**Step 3: Smoke test**

```bash
source .env
# Get a real token from the DB
TOKEN=$(curl -s "https://ppmhntfohxjcqyzfbpui.supabase.co/rest/v1/newsletter_subscribers?select=unsubscribe_token&limit=1" \
  -H "apikey: $VITE_EXTERNAL_SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $VITE_EXTERNAL_SUPABASE_SERVICE_KEY" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>console.log(JSON.parse(d)[0]?.unsubscribe_token))")

curl -si "https://ppmhntfohxjcqyzfbpui.supabase.co/functions/v1/track-open?t=$TOKEN" \
  -H "Authorization: Bearer $VITE_EXTERNAL_SUPABASE_ANON_KEY" | head -5
```

Expected: `HTTP/2 200`, `content-type: image/gif`

**Step 4: Verify DB updated**

```bash
curl -s "https://ppmhntfohxjcqyzfbpui.supabase.co/rest/v1/newsletter_subscribers?select=email,last_email_open_at&limit=1" \
  -H "apikey: $VITE_EXTERNAL_SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $VITE_EXTERNAL_SUPABASE_SERVICE_KEY"
```

Expected: `last_email_open_at` is a recent timestamp.

**Step 5: Commit**

```bash
git add supabase/functions/track-open/index.ts
git commit -m "feat: add track-open pixel edge function"
```

---

### Task 3: track-visit Edge Function

**Files:**
- Create: `supabase/functions/track-visit/index.ts`

**Step 1: Create the function**

```typescript
// supabase/functions/track-visit/index.ts
import { createClient } from "npm:@supabase/supabase-js@2";

const ALLOWED_ORIGINS = ["https://mikemaze.nl", "http://localhost:8080"];

function corsHeaders(origin: string | null) {
  const allowed = origin && ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    "Access-Control-Allow-Origin": allowed,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  };
}

Deno.serve(async (req: Request) => {
  const origin = req.headers.get("origin");

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders(origin) });
  }

  // Always return 200 — never surface errors to frontend
  const ok = () => new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { "Content-Type": "application/json", ...corsHeaders(origin) },
  });

  try {
    const { token } = await req.json();
    if (!token || typeof token !== "string") return ok();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    await supabase
      .from("newsletter_subscribers")
      .update({ last_visit_at: new Date().toISOString() })
      .eq("unsubscribe_token", token);
  } catch (e) {
    console.error("track-visit error:", e);
  }

  return ok();
});
```

**Step 2: Deploy**

```bash
source .env
SUPABASE_ACCESS_TOKEN="$MikeMaze_IT_ACL_TOKEN" npx supabase functions deploy track-visit --project-ref ppmhntfohxjcqyzfbpui
```

Expected: `Deployed Functions on project ppmhntfohxjcqyzfbpui: track-visit`

**Step 3: Smoke test**

```bash
source .env
TOKEN=$(curl -s "https://ppmhntfohxjcqyzfbpui.supabase.co/rest/v1/newsletter_subscribers?select=unsubscribe_token&limit=1" \
  -H "apikey: $VITE_EXTERNAL_SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $VITE_EXTERNAL_SUPABASE_SERVICE_KEY" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>console.log(JSON.parse(d)[0]?.unsubscribe_token))")

curl -s -X POST "https://ppmhntfohxjcqyzfbpui.supabase.co/functions/v1/track-visit" \
  -H "Authorization: Bearer $VITE_EXTERNAL_SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -H "Origin: https://mikemaze.nl" \
  -d "{\"token\":\"$TOKEN\"}"
```

Expected: `{"ok":true}`

**Step 4: Commit**

```bash
git add supabase/functions/track-visit/index.ts
git commit -m "feat: add track-visit beacon edge function"
```

---

### Task 4: Frontend Beacon (Index.tsx + BlogPost.tsx)

**Files:**
- Modify: `src/pages/Index.tsx`
- Modify: `src/pages/BlogPost.tsx`
- Create: `src/lib/trackVisit.ts`

**Step 1: Create shared trackVisit utility**

```typescript
// src/lib/trackVisit.ts
const TRACK_URL = "https://ppmhntfohxjcqyzfbpui.supabase.co/functions/v1/track-visit";
const ANON_KEY = import.meta.env.VITE_EXTERNAL_SUPABASE_ANON_KEY;
const STORAGE_KEY = "mm_ut";

export function initVisitTracking(searchParams?: URLSearchParams) {
  // Store token from URL if present
  const ut = searchParams?.get("ut");
  if (ut) localStorage.setItem(STORAGE_KEY, ut);

  // Fire beacon if we have a token
  const token = localStorage.getItem(STORAGE_KEY);
  if (!token) return;

  fetch(TRACK_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${ANON_KEY}`,
    },
    body: JSON.stringify({ token }),
  }).catch(() => {}); // silent fail
}
```

**Step 2: Add to Index.tsx** — inside the existing `useEffect`:

```typescript
// Add import at top of Index.tsx
import { useSearchParams } from "react-router-dom";
import { initVisitTracking } from "@/lib/trackVisit";

// Inside the Index component, add:
const [searchParams] = useSearchParams();

useEffect(() => {
  initVisitTracking(searchParams);
}, []); // eslint-disable-line react-hooks/exhaustive-deps
```

**Step 3: Add to BlogPost.tsx** — add after existing imports:

```typescript
// Add import at top of BlogPost.tsx
import { useSearchParams } from "react-router-dom";
import { initVisitTracking } from "@/lib/trackVisit";

// Inside BlogPost component, add alongside existing useParams:
const [searchParams] = useSearchParams();

useEffect(() => {
  initVisitTracking(searchParams);
}, []); // eslint-disable-line react-hooks/exhaustive-deps
```

**Step 4: Build to verify no errors**

```bash
npm run build 2>&1 | tail -5
```

Expected: `✓ built in` — no errors.

**Step 5: Commit**

```bash
git add src/lib/trackVisit.ts src/pages/Index.tsx src/pages/BlogPost.tsx
git commit -m "feat: add visit tracking beacon with localStorage token persistence"
```

---

### Task 5: Update subscribe function — add pixel + ?ut= links

**Files:**
- Modify: `supabase/functions/subscribe/index.ts`

**Step 1: Add tracking pixel to WELCOME_HTML**

In `supabase/functions/subscribe/index.ts`, add the pixel as the last element before `</body>` in `WELCOME_HTML`:

```typescript
// Add this before the closing </body> tag in WELCOME_HTML:
`<img src="https://ppmhntfohxjcqyzfbpui.supabase.co/functions/v1/track-open?t=${unsubscribeToken}" width="1" height="1" style="display:none;border:0;" alt="" />`
```

**Step 2: Update CTA button link to include ?ut= token**

In `WELCOME_HTML`, change the blog link:
```typescript
// Before:
href="https://mikemaze.nl"
// After:
href="https://mikemaze.nl?ut=${unsubscribeToken}"
```

**Step 3: Deploy updated subscribe function**

```bash
source .env
SUPABASE_ACCESS_TOKEN="$MikeMaze_IT_ACL_TOKEN" npx supabase functions deploy subscribe --project-ref ppmhntfohxjcqyzfbpui
```

Expected: `Deployed Functions on project ppmhntfohxjcqyzfbpui: subscribe`

**Step 4: Commit**

```bash
git add supabase/functions/subscribe/index.ts
git commit -m "feat: add tracking pixel and ?ut= token to welcome email"
```

---

### Task 6: send-reminders Edge Function

**Files:**
- Create: `supabase/functions/send-reminders/index.ts`

**Step 1: Create the function**

```typescript
// supabase/functions/send-reminders/index.ts
import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const RESEND_KEY = Deno.env.get("RESEND_API_KEY")!;
const SITE = "https://mikemaze.nl";
const PIXEL_BASE = "https://ppmhntfohxjcqyzfbpui.supabase.co/functions/v1/track-open";

type Interval = "1w" | "1m" | "3m" | "6m" | "1y";

const INTERVALS: { id: Interval; minDays: number; maxDays: number }[] = [
  { id: "1w",  minDays: 7,   maxDays: 8   },
  { id: "1m",  minDays: 30,  maxDays: 32  },
  { id: "3m",  minDays: 90,  maxDays: 93  },
  { id: "6m",  minDays: 180, maxDays: 185 },
  { id: "1y",  minDays: 365, maxDays: 370 },
];

function link(path: string, token: string) {
  return `${SITE}${path}?ut=${token}`;
}

function pixel(token: string) {
  return `<img src="${PIXEL_BASE}?t=${token}" width="1" height="1" style="display:none;border:0;" alt="" />`;
}

function unsubLink(token: string) {
  return `${SITE}/unsubscribe?token=${token}`;
}

function footer(email: string, token: string) {
  return `
    <p style="margin:24px 0 0;font-size:12px;color:#555566;line-height:1.6;text-align:center;">
      Je ontvangt dit omdat ${email} zich heeft aangemeld voor de Mike Maze IT Adventures nieuwsbrief.<br/>
      <a href="${unsubLink(token)}" style="color:#00d4ff;">Afmelden</a>
    </p>
    ${pixel(token)}
  `;
}

function buildEmail(interval: Interval, email: string, token: string): { subject: string; html: string } {
  const blogLink = link("/", token);
  const base = `
    <!DOCTYPE html><html lang="nl"><head><meta charset="UTF-8"/></head>
    <body style="margin:0;padding:32px 16px;background:#0a0a0f;font-family:system-ui,sans-serif;color:#e0e0e0;">
    <div style="max-width:540px;margin:0 auto;">
  `;
  const end = `</div></body></html>`;

  switch (interval) {
    case "1w": return {
      subject: "hey, still there?",
      html: `${base}
        <p style="font-size:16px;line-height:1.7;">hey!</p>
        <p style="font-size:16px;line-height:1.7;">Ik zag dat je je hebt aangemeld voor de nieuwsbrief maar nog niet terug bent geweest op <a href="${blogLink}" style="color:#00d4ff;">mikemaze.nl</a>. Geen probleem — ik wilde alleen even checken of de welkomstmail niet in spam was beland of zo.</p>
        <p style="font-size:16px;line-height:1.7;">Er zijn de afgelopen week wat nieuwe posts bijgekomen als je nieuwsgierig bent. Kom gerust eens kijken.</p>
        <p style="font-size:16px;line-height:1.7;">— mike</p>
        ${footer(email, token)}${end}`,
    };
    case "1m": return {
      subject: "a month already? here's what you missed",
      html: `${base}
        <p style="font-size:16px;line-height:1.7;">Hi!</p>
        <p style="font-size:16px;line-height:1.7;">Waanzinnig dat het al een maand geleden is. Ik schrijf de laatste tijd veel over AI-automatisering en developer tools — dingen die ik zelf elke dag gebruik. Misschien precies wat jij zoekt.</p>
        <p style="font-size:16px;line-height:1.7;">Kom gerust even langs op <a href="${blogLink}" style="color:#00d4ff;">mikemaze.nl</a> als je een momentje hebt.</p>
        <p style="font-size:16px;line-height:1.7;">— Mike</p>
        ${footer(email, token)}${end}`,
    };
    case "3m": return {
      subject: "checking in on you",
      html: `${base}
        <p style="font-size:16px;line-height:1.7;">Hey,</p>
        <p style="font-size:16px;line-height:1.7;">Het is al een paar maanden geleden en ik zat te denken — schrijf ik eigenlijk over de goede dingen? Ik zou het echt fijn vinden om te horen wat je terug zou brengen naar de blog. Stuur gerust een reply op dit bericht.</p>
        <p style="font-size:16px;line-height:1.7;">In de tussentijd, hier is mijn beste post van dit kwartaal: <a href="${blogLink}" style="color:#00d4ff;">check it out →</a></p>
        <p style="font-size:16px;line-height:1.7;">— Mike</p>
        ${footer(email, token)}${end}`,
    };
    case "6m": return {
      subject: "honestly? I miss having you around",
      html: `${base}
        <p style="font-size:16px;line-height:1.7;">Hoi,</p>
        <p style="font-size:16px;line-height:1.7;">Een half jaar. Dat is lang. Ik weet niet precies waarom je bent afgedwaald — misschien werd het leven druk, misschien klikte de content niet. Beide zijn prima.</p>
        <p style="font-size:16px;line-height:1.7;">Ik schrijf nog steeds over de dingen waar ik enthousiast van word. Als dat nog interessant klinkt, de deur staat altijd open: <a href="${blogLink}" style="color:#00d4ff;">mikemaze.nl</a></p>
        <p style="font-size:16px;line-height:1.7;">— Mike</p>
        ${footer(email, token)}${end}`,
    };
    case "1y": return {
      subject: "ok it's been a whole year. I had to say something.",
      html: `${base}
        <p style="font-size:16px;line-height:1.7;">Een heel jaar!</p>
        <p style="font-size:16px;line-height:1.7;">Ik twijfelde of ik dit moest sturen. Maar toen dacht ik: als iemand die ik kende een jaar niks van zich had laten horen, zou ik toch op zijn minst even een berichtje sturen. Dus: hoi.</p>
        <p style="font-size:16px;line-height:1.7;">Ik schrijf nog steeds. De blog is flink gegroeid. Als je benieuwd bent: <a href="${blogLink}" style="color:#00d4ff;">kom kijken wat er nieuw is →</a></p>
        <p style="font-size:16px;line-height:1.7;">En zo niet — geen hard feelings. Er staat een afmeldlink hieronder.</p>
        <p style="font-size:16px;line-height:1.7;">— Mike</p>
        ${footer(email, token)}${end}`,
    };
  }
}

Deno.serve(async (req: Request) => {
  // Only accept requests with service role key
  const auth = req.headers.get("Authorization") ?? "";
  if (!auth.includes(SERVICE_KEY)) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

  const { data: subscribers, error } = await supabase
    .from("newsletter_subscribers")
    .select("id, email, unsubscribe_token, last_active_at, reminders_sent");

  if (error) {
    console.error("Failed to fetch subscribers:", error);
    return new Response(JSON.stringify({ error: "DB error" }), { status: 500 });
  }

  const now = Date.now();
  let sent = 0;
  let skipped = 0;

  for (const sub of subscribers ?? []) {
    try {
      const lastActive = new Date(sub.last_active_at ?? sub.created_at).getTime();
      const daysInactive = (now - lastActive) / 86_400_000;
      const alreadySent: Interval[] = sub.reminders_sent ?? [];

      const interval = INTERVALS.find(
        (i) => daysInactive >= i.minDays && daysInactive < i.maxDays
      );

      if (!interval || alreadySent.includes(interval.id)) {
        skipped++;
        continue;
      }

      const { subject, html } = buildEmail(interval.id, sub.email, sub.unsubscribe_token);

      const res = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${RESEND_KEY}`,
        },
        body: JSON.stringify({
          from: "Mike Maze <newsletter@mikemaze.nl>",
          to: [sub.email],
          subject,
          html,
        }),
      });

      if (!res.ok) {
        console.error(`Resend error for ${sub.email}:`, await res.text());
        continue;
      }

      // Mark interval as sent
      await supabase
        .from("newsletter_subscribers")
        .update({ reminders_sent: [...alreadySent, interval.id] })
        .eq("id", sub.id);

      await supabase.from("reminder_log").insert({
        subscriber_id: sub.id,
        interval: interval.id,
      });

      sent++;
    } catch (e) {
      console.error(`Error processing subscriber ${sub.id}:`, e);
    }
  }

  return new Response(JSON.stringify({ sent, skipped }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
```

**Step 2: Deploy**

```bash
source .env
SUPABASE_ACCESS_TOKEN="$MikeMaze_IT_ACL_TOKEN" npx supabase functions deploy send-reminders --project-ref ppmhntfohxjcqyzfbpui
```

Expected: `Deployed Functions on project ppmhntfohxjcqyzfbpui: send-reminders`

**Step 3: Smoke test (dry run — no real subscribers in window yet)**

```bash
source .env
curl -s -X POST "https://ppmhntfohxjcqyzfbpui.supabase.co/functions/v1/send-reminders" \
  -H "Authorization: Bearer $VITE_EXTERNAL_SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json"
```

Expected: `{"sent":0,"skipped":N}` — N = number of subscribers not in any window.

**Step 4: Commit**

```bash
git add supabase/functions/send-reminders/index.ts
git commit -m "feat: add send-reminders edge function with 5-interval escalating tone"
```

---

### Task 7: pg_cron Migration — schedule daily job

**Files:**
- Create: `supabase/migrations/20260301020000_reminder_cron.sql`

**Step 1: Create the migration**

```sql
-- supabase/migrations/20260301020000_reminder_cron.sql
-- Requires pg_cron and pg_net extensions (enabled by default on Supabase)

-- Remove existing job if any
SELECT cron.unschedule('daily-re-engagement') WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'daily-re-engagement'
);

-- Schedule daily at 09:00 UTC
SELECT cron.schedule(
  'daily-re-engagement',
  '0 9 * * *',
  $$
  SELECT net.http_post(
    url := 'https://ppmhntfohxjcqyzfbpui.supabase.co/functions/v1/send-reminders',
    headers := json_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.service_role_key', true)
    )::jsonb,
    body := '{}'::jsonb
  );
  $$
);
```

**Step 2: Apply via Management API**

```bash
source .env
TOKEN=$(grep MikeMaze_IT_ACL_TOKEN .env | cut -d'"' -f2)

# First set the service role key as a DB setting
curl -s -X POST "https://api.supabase.com/v1/projects/ppmhntfohxjcqyzfbpui/database/query" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"query\":\"ALTER DATABASE postgres SET app.service_role_key = '$(grep VITE_EXTERNAL_SUPABASE_SERVICE_KEY .env | cut -d'\"' -f2)'\"}" \
  -w "\nHTTP:%{http_code}"
```

Then apply the cron migration:

```bash
CRON_SQL=$(cat supabase/migrations/20260301020000_reminder_cron.sql | tr '\n' ' ' | sed 's/"/\\"/g')
curl -s -X POST "https://api.supabase.com/v1/projects/ppmhntfohxjcqyzfbpui/database/query" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"query\":\"${CRON_SQL}\"}" \
  -w "\nHTTP:%{http_code}"
```

Expected: `HTTP:201`

**Step 3: Verify cron job is scheduled**

```bash
curl -s -X POST "https://api.supabase.com/v1/projects/ppmhntfohxjcqyzfbpui/database/query" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"query":"SELECT jobname, schedule, active FROM cron.job WHERE jobname = '"'"'daily-re-engagement'"'"'"}'
```

Expected: `[{"jobname":"daily-re-engagement","schedule":"0 9 * * *","active":true}]`

**Step 4: Commit**

```bash
git add supabase/migrations/20260301020000_reminder_cron.sql
git commit -m "feat: schedule daily re-engagement cron at 09:00 UTC"
```

---

### Task 8: Final verification + update docs

**Step 1: Run tests**

```bash
npm test
```

Expected: `30 passed (30)` — all existing tests still pass.

**Step 2: Build**

```bash
npm run build 2>&1 | tail -5
```

Expected: `✓ built in` — no errors.

**Step 3: Update docs/todo.md**

Add to completed section:
- Re-engagement email system (track-open, track-visit, send-reminders functions)
- pg_cron daily job at 09:00 UTC
- Frontend visit beacon with localStorage token persistence

**Step 4: Push**

```bash
git push origin main
```

---

## Summary of New Files

| File | Purpose |
|------|---------|
| `supabase/migrations/20260301010000_re_engagement_schema.sql` | DB columns + reminder_log table |
| `supabase/migrations/20260301020000_reminder_cron.sql` | pg_cron daily schedule |
| `supabase/functions/track-open/index.ts` | Email open pixel handler |
| `supabase/functions/track-visit/index.ts` | Site visit beacon |
| `supabase/functions/send-reminders/index.ts` | Daily reminder sender |
| `src/lib/trackVisit.ts` | Shared frontend tracking utility |
| `src/pages/Index.tsx` | +beacon on homepage |
| `src/pages/BlogPost.tsx` | +beacon on blog posts |
| `supabase/functions/subscribe/index.ts` | +pixel +?ut= in welcome email |
