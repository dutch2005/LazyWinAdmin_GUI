

# Admin Panel Overhaul

The current admin panel is a single-page blog post manager. This plan upgrades it into a full-featured admin dashboard with sidebar navigation, multiple sections, and modern 2026-era admin features.

---

## What You'll Get

### 1. Sidebar Navigation Layout
Replace the current single-view layout with a persistent sidebar and routed content area. Sections:
- **Dashboard** (home/overview)
- **Blog Posts** (existing, refined)
- **Messages** (contact form submissions)
- **Subscribers** (newsletter list)
- **Social Sharing** (promote posts)
- **Security** (session info, audit)
- **Settings** (site preferences)

### 2. Dashboard Overview Page
A landing page with key metrics at a glance:
- Total blog posts / published vs draft count
- Contact messages (unread count)
- Newsletter subscriber count
- Recent activity feed (latest posts created/edited)
- Quick-action buttons (new post, view site)

### 3. Contact Messages Panel
View all `contact_messages` submitted through the site:
- List view with name, email, subject, date
- Expandable message detail
- No editing needed -- read-only inbox

### 4. Newsletter Subscribers Panel
View all `newsletter_subscribers`:
- List with email and signup date
- Total count
- Export as CSV button (client-side download)

### 5. Social Sharing / Promotion Panel
When you publish or select a blog post, generate share-ready links and copy-paste content for social media:
- Auto-generate share URLs for LinkedIn, X/Twitter, Facebook, WhatsApp
- Auto-generate a promotional snippet (title + excerpt + URL) for copy-paste
- "Copy to clipboard" buttons for each platform
- No API keys required -- uses standard share URL schemes

### 6. Security Panel
- Show current logged-in session info (email, last sign-in)
- Password change form (calls `updateUser({ password })`)
- Active sessions overview (from Supabase auth)
- Login audit: show last 5 login timestamps (stored in a new `admin_audit_log` table)

### 7. Settings Panel
- Quick toggles placeholder for future features (e.g., maintenance mode flag)
- Site metadata display (project info)

---

## Technical Details

### New Database Table
A new `admin_audit_log` table to track admin actions:

```sql
create table public.admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  action text not null,
  details text,
  created_at timestamptz not null default now()
);

alter table public.admin_audit_log enable row level security;

create policy "Admins can read audit logs"
  on public.admin_audit_log for select
  using (public.has_role(auth.uid(), 'admin'));

create policy "Admins can insert audit logs"
  on public.admin_audit_log for insert
  with check (public.has_role(auth.uid(), 'admin'));
```

### File Structure

New/modified files:

```text
src/pages/Admin.tsx              -- refactor to sidebar layout + router
src/components/admin/AdminSidebar.tsx
src/components/admin/DashboardPanel.tsx
src/components/admin/BlogPostsPanel.tsx   -- extracted from current Admin.tsx
src/components/admin/MessagesPanel.tsx
src/components/admin/SubscribersPanel.tsx
src/components/admin/SocialSharePanel.tsx
src/components/admin/SecurityPanel.tsx
src/components/admin/SettingsPanel.tsx
```

### Routing
The admin page will use internal state-based navigation (no new routes needed -- keeps the single `/admin` route). The sidebar switches between panels via local state.

### Social Share URL Patterns
No APIs needed. Standard URL schemes:
- LinkedIn: `https://www.linkedin.com/sharing/share-offsite/?url=ENCODED_URL`
- X/Twitter: `https://twitter.com/intent/tweet?text=ENCODED_TEXT&url=ENCODED_URL`
- Facebook: `https://www.facebook.com/sharer/sharer.php?u=ENCODED_URL`
- WhatsApp: `https://wa.me/?text=ENCODED_TEXT`

### Styling
All panels will use the existing dark tech theme (`card-glass`, `bg-background`, `text-primary`, etc.) for a cohesive look. The sidebar will use the existing sidebar CSS variables already defined in `index.css`.

### Security Considerations
- All new panels query tables that already have RLS policies restricting access to admins
- Audit log entries are inserted on login and key actions (post create/edit/delete)
- Password change uses Supabase's built-in `updateUser` -- no custom endpoint needed

