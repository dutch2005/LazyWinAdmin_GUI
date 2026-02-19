
# IT Adventures — Full Feature Implementation Plan

This plan covers all five requests in a logical build order, from frontend enhancements to backend integration.

---

## Overview of Changes

```text
1. Blog post detail page (routing + content)
2. Expanded About section (photo + CV: jobs, certs, contact)
3. Contact form section (replacing the minimal newsletter section)
4. Lovable Cloud backend + Admin panel (database-driven blog posts)
5. Mobile responsiveness audit + NL/EN toggle verification
```

---

## 1. Blog Post Detail Page

A new page `/blog/:slug` will be created so clicking any blog card navigates to a full article.

### What changes:
- Convert from `BrowserRouter` single-page to multi-page routing. The `/` route keeps the current homepage, and `/blog/:slug` shows a full article.
- Create `src/pages/BlogPost.tsx` — a detail page that reads the `slug` from the URL, looks up the post in `blogPosts.ts`, and renders the full article.
- Extend the `BlogPost` interface in `src/data/blogPosts.ts` with a `content` field (bilingual long-form text).
- Add "Previous" / "Next" navigation between posts at the bottom of the article.
- Update `BlogSection.tsx` so article cards link to `/blog/:slug` using React Router `<Link>`.
- Add the new route in `App.tsx`.
- Add a "Back to blog" link in the Navbar when on a detail page.

---

## 2. About Section — Personal Photo + Real CV Details

The About section will be split into a richer layout with:

- **Profile photo**: A placeholder profile image slot will be added. You can replace `src/assets/profile.jpg` with your real photo at any time.
- **Work history timeline**: A vertical timeline component showing your career milestones (IT roles, companies, years) — bilingual NL/EN.
- **Certifications grid**: Icon-tagged cert badges (e.g., Microsoft, Azure, CompTIA) — bilingual labels.
- **Contact info strip**: Email, LinkedIn, location — clickable links.
- The existing skills grid and terminal card will be repositioned to fit the expanded layout.
- New translation keys will be added to `LanguageContext.tsx` for all new content.

### Placeholder CV data used (you can update these directly in the data file):
- Work history: 3–4 sample IT roles with realistic descriptions
- Certifications: Microsoft 365, Azure Administrator, CompTIA Security+, etc.
- Contact: mike@itadventures.nl, LinkedIn link placeholder, location NL

---

## 3. Contact Form Section

The current `NewsletterSection` (which only has an email input) will be transformed into a proper **Contact section** with a newsletter signup kept separately or merged.

### New contact section (`src/components/ContactSection.tsx`):
- Full name field
- Email field
- Subject field
- Message textarea (min 4 rows)
- Send button with loading state
- Client-side validation using Zod + react-hook-form (already installed)
- Success state with confirmation message
- Initially the form will log/show success locally (no backend). Once the Cloud backend is set up in step 4, it can optionally save messages to a `contact_messages` table.

### Translations added for both NL and EN:
- Form labels, placeholders, validation messages, success text

### Layout:
- Left: contact info (email, social links, location)
- Right: the form
- A separate smaller newsletter email signup stays below (or is merged into footer)

---

## 4. Lovable Cloud Backend + Admin Panel

This is the largest change. It connects the blog to a real database so posts can be created and managed without touching code.

### Database schema (Lovable Cloud):

```text
blog_posts table:
  id            uuid (primary key)
  slug          text (unique)
  category      text ('ai' | 'news' | 'tutorials' | 'tools')
  date          date
  read_time     integer
  featured      boolean
  title_nl      text
  title_en      text
  excerpt_nl    text
  excerpt_en    text
  content_nl    text
  content_en    text
  image_url     text (nullable)
  published     boolean (default false)
  created_at    timestamptz
  updated_at    timestamptz

contact_messages table:
  id         uuid
  name       text
  email      text
  subject    text
  message    text
  created_at timestamptz

newsletter_subscribers table:
  id         uuid
  email      text (unique)
  created_at timestamptz
```

### Authentication for admin:
- Supabase Auth email/password login
- A simple `/admin` route protected by an auth check
- A `user_roles` table (separate from profiles, as required) using the `app_role` enum with `admin` role
- `has_role()` security definer function to check admin status server-side
- RLS policies: public can read published posts; only admins can insert/update/delete

### Admin panel (`src/pages/Admin.tsx`):
- Login page at `/admin/login`
- Dashboard at `/admin` showing:
  - List of all blog posts (published/draft status)
  - "New post" button → form to create a post with all fields (title NL/EN, excerpt NL/EN, content NL/EN, category, featured toggle, publish toggle)
  - Edit button per post
  - Delete button per post
- Uses Supabase client (Lovable Cloud) for all CRUD

### Frontend blog update:
- `BlogSection.tsx` and `BlogPost.tsx` will query the `blog_posts` table instead of the local `blogPosts.ts` file
- Loading skeletons shown while fetching
- The local `src/data/blogPosts.ts` becomes the seeding source (initial data will be inserted into the DB)

---

## 5. Mobile Responsiveness Audit

During implementation, the following mobile-specific checks will be applied:

- Hero: text sizes scaled down (`text-4xl` on mobile vs `text-8xl` on desktop)
- Navbar: hamburger menu already exists; language toggle placement verified on small screens
- BlogSection: card grid stacks to 1 column on mobile
- AboutSection: photo + timeline stack vertically on mobile
- ContactSection: two-column layout collapses to single column on mobile
- Admin panel: basic mobile table/list view

---

## Technical Implementation Order

```text
Step 1 → Add routing for /blog/:slug + blog detail page
Step 2 → Extend blogPosts data with content + update BlogSection links
Step 3 → Update About section with photo placeholder + CV data
Step 4 → Create ContactSection component + wire into Index page
Step 5 → Set up Lovable Cloud (migrations for blog_posts, contact_messages, newsletter_subscribers, user_roles)
Step 6 → Add RLS policies + has_role function
Step 7 → Build Admin panel with auth guard + CRUD forms
Step 8 → Update BlogSection + BlogPost page to fetch from Supabase
Step 9 → Update ContactSection to save to contact_messages table
Step 10 → Update NewsletterSection to save to newsletter_subscribers table
Step 11 → Add translation keys for all new content
Step 12 → Mobile audit pass across all new components
```

---

## Files Created / Modified

| File | Action |
|---|---|
| `src/App.tsx` | Add `/blog/:slug`, `/admin`, `/admin/login` routes |
| `src/pages/BlogPost.tsx` | New — blog detail page |
| `src/pages/Admin.tsx` | New — admin dashboard |
| `src/pages/AdminLogin.tsx` | New — admin login |
| `src/components/BlogSection.tsx` | Update cards to use `<Link>`, fetch from DB |
| `src/components/AboutSection.tsx` | Add photo, timeline, certs, contact |
| `src/components/ContactSection.tsx` | New — full contact form |
| `src/components/NewsletterSection.tsx` | Simplify to email-only signup saving to DB |
| `src/data/blogPosts.ts` | Add `content` field (used as seed data) |
| `src/contexts/LanguageContext.tsx` | Add ~30 new translation keys |
| `src/pages/Index.tsx` | Add `ContactSection`, keep structure |
| `supabase/migrations/` | Blog posts, contact messages, subscribers, roles schema |
| `src/assets/profile.jpg` | Placeholder — replace with your real photo |
| `src/integrations/supabase/` | Auto-generated types after migration |
