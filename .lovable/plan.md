
# IT Adventures — Complete Update Plan

This plan covers all the items you mentioned: migrating to your own Supabase instance, protecting your email address from scrapers, updating your email, updating LinkedIn URL, updating certifications (Microsoft 365 + 3CX V20), and updating your work history once you paste it.

---

## What will be done

### 1. Supabase Migration (your own project)

You'll provide your project URL (e.g. `https://yourproject.supabase.co`) and your Anon/Publishable key. These will be stored as secrets in the project so they are never exposed in source code.

The `.env` file and `src/integrations/supabase/client.ts` are auto-generated — I will update the environment variables to point to your own Supabase instance.

**Data migration approach:**
- The existing Lovable Cloud database contains your blog posts, contact messages, newsletter subscribers, and user roles.
- I will export the blog posts as seed data so they can be re-inserted into your own Supabase project.
- You'll need to re-run the same database migrations (schema) in your own Supabase project — I'll provide the SQL to run.
- Contact messages and newsletter subscribers can be exported to CSV from the Cloud backend view.

**Schema you need to recreate in your Supabase project** (SQL to run in your Supabase SQL editor):
```sql
-- App role enum
create type public.app_role as enum ('admin', 'moderator', 'user');

-- User roles table
create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  role app_role not null,
  unique (user_id, role)
);
alter table public.user_roles enable row level security;

-- has_role security definer function
create or replace function public.has_role(_user_id uuid, _role app_role)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.user_roles where user_id = _user_id and role = _role)
$$;

-- Blog posts
create table public.blog_posts (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  category text not null,
  date date not null default current_date,
  read_time integer not null default 5,
  featured boolean not null default false,
  title_nl text not null,
  title_en text not null,
  excerpt_nl text not null default '',
  excerpt_en text not null default '',
  content_nl text not null default '',
  content_en text not null default '',
  image_url text,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.blog_posts enable row level security;
create policy "Published posts are public" on public.blog_posts for select using (published = true);
create policy "Admins can manage all posts" on public.blog_posts for all using (has_role(auth.uid(), 'admin'::app_role)) with check (has_role(auth.uid(), 'admin'::app_role));

-- Contact messages
create table public.contact_messages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null,
  subject text not null,
  message text not null,
  created_at timestamptz not null default now()
);
alter table public.contact_messages enable row level security;
create policy "Anyone can send contact messages" on public.contact_messages for insert with check (length(name) > 0 and length(email) > 0 and length(message) > 0);
create policy "Admins can read contact messages" on public.contact_messages for select using (has_role(auth.uid(), 'admin'::app_role));

-- Newsletter subscribers
create table public.newsletter_subscribers (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  created_at timestamptz not null default now()
);
alter table public.newsletter_subscribers enable row level security;
create policy "Anyone can subscribe" on public.newsletter_subscribers for insert with check (length(email) > 0);
create policy "Admins can read subscribers" on public.newsletter_subscribers for select using (has_role(auth.uid(), 'admin'::app_role));
```

After running the schema, you need to sign up a user in your own Supabase Auth and then insert your admin role:
```sql
insert into public.user_roles (user_id, role) values ('<your-new-user-id>', 'admin');
```

---

### 2. Email Privacy — No Scrapers

Currently your email `mike@itadventures.nl` appears in plain text in two places:
- `src/components/AboutSection.tsx` (terminal card + mailto link)
- `src/components/ContactSection.tsx` (contact info card)

**Fix:** Replace the plain `mailto:mike@itadventures.nl` links with a **CSS-obfuscated email** that renders visually correctly but is invisible to bots scraping raw HTML. This uses the CSS `direction: rtl` + Unicode reversal trick — no JavaScript required, works in all browsers, and email clients can still click it normally.

Additionally, the new email `dutch2005@xtremeweb.xyz` will be used everywhere instead of `mike@itadventures.nl`.

The terminal card in `AboutSection` will also be updated to reflect the new email.

---

### 3. Email Address Update

Every occurrence of `mike@itadventures.nl` will be replaced with `dutch2005@xtremeweb.xyz`:

| File | Location |
|---|---|
| `src/components/AboutSection.tsx` | mailto link + terminal card |
| `src/components/ContactSection.tsx` | contact info card + mailto link |
| `src/pages/AdminLogin.tsx` | placeholder text |

---

### 4. LinkedIn URL Update

Current URL: `https://linkedin.com/in/michaelmaertzdorf`
New URL: `https://www.linkedin.com/in/michael-maertzdorf-b9231420/`

Updated in:
- `src/components/AboutSection.tsx`
- `src/components/ContactSection.tsx`

---

### 5. Certifications Update

You confirmed you hold:
- **Microsoft 365 Certified** (already present)
- **3CX V20** (new — to be added)

The current certifications list also includes placeholder entries (Azure AZ-104, CompTIA Security+, ITIL, GitHub Foundations, n8n) that you haven't confirmed. These will be **removed or kept** — please confirm in your next message which ones are real.

For now, the plan is to update the grid to show only confirmed certs plus 3CX V20. If you want to keep the others, just say so.

---

### 6. Work History Update

You will paste your real work history in the next message. Once received, `src/components/AboutSection.tsx` will be updated with your actual:
- Job titles (bilingual NL/EN)
- Company names
- Employment periods
- Role descriptions

---

## Files to be changed

| File | Change |
|---|---|
| `.env` (auto-generated) | New Supabase URL + key (via secrets) |
| `src/components/AboutSection.tsx` | New email, LinkedIn URL, certifications, work history, email obfuscation |
| `src/components/ContactSection.tsx` | New email, LinkedIn URL, email obfuscation |
| `src/pages/AdminLogin.tsx` | Update email placeholder |

---

## What I need from you next

Please paste the following in your next message:
1. **Your real work history** (job title, company, years, description — Dutch/English either is fine)
2. **Which certifications to keep** from the current list (Azure AZ-104, CompTIA Security+, ITIL, GitHub Foundations, n8n) — or confirm to remove them all and only show M365 + 3CX V20
3. **Your Supabase Project URL** (format: `https://xxxxxx.supabase.co`)
4. **Your Anon/Publishable key** (starts with `eyJ...`)
