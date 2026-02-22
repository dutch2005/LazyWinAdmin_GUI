

# Phase 1-4: Complete Blog Enhancement Plan

This is a comprehensive 4-phase upgrade to transform your blog into a professional, discoverable, and automated content platform.

---

## Phase 1 -- SEO and Reading Experience

### 1A. Dynamic SEO Meta Tags (Open Graph + JSON-LD)
- Create a reusable `SEOHead` component using `react-helmet-async` (new dependency) that sets `<title>`, Open Graph, Twitter Card, and JSON-LD structured data per blog post
- On the homepage: default site-level meta tags
- On blog posts: dynamic per-post tags with title, excerpt, image, and article schema
- JSON-LD `BlogPosting` schema for Google rich results (author, datePublished, headline, etc.)

### 1B. Reading Progress Bar
- A thin, fixed-to-top progress bar on blog post pages that fills as the reader scrolls
- Uses the existing `--primary` cyan color for brand consistency
- Sits just below the navbar (z-indexed properly)

### 1C. Table of Contents (TOC)
- Auto-generated from `## ` and `### ` headings in post content
- Displayed as a sticky sidebar on desktop, collapsible on mobile
- Clicking a TOC item smooth-scrolls to the heading
- Headings get auto-generated `id` attributes for anchor linking

### 1D. Related Posts Section
- At the bottom of each blog post, show 2-3 related posts
- Matching logic: same category first, then other recent posts
- Uses the existing card-glass style for consistency

---

## Phase 2 -- Search, Filtering and Visual Polish

### 2A. Blog Search Bar
- Add a search input above the blog category filters on the homepage
- Client-side filtering on title and excerpt (both languages)
- Debounced input with a search icon and clear button
- Search results highlight in the existing post grid

### 2B. Enhanced Code Syntax Highlighting
- Replace the plain `<pre><code>` blocks with syntax-highlighted code using `highlight.js` (new dependency, lightweight)
- Support common languages: JavaScript, TypeScript, PowerShell, Python, Bash, JSON
- Use a dark theme that matches the site's navy/cyan palette
- Add a "Copy code" button on each code block

### 2C. Visual Polish and Animations
- Add `animate-fade-in-up` stagger animations to blog post content paragraphs
- Smooth transitions on category filter changes
- Better image handling: if `image_url` exists, display a cover image hero on the blog post page
- Improve blog card hover effects with subtle scale transforms

### 2D. Better Blog Post Layout
- Wider content area on large screens with proper typography spacing
- Pull quotes or callout blocks support in markdown (using `> ` blockquote syntax)
- Better list styling with proper indentation
- Image support in markdown content (`![alt](url)` syntax)

---

## Phase 3 -- Admin Upgrades

### 3A. Cover Image Uploads
- Create a storage bucket `blog-images` on your Supabase instance (you'll run the SQL)
- Add an image upload widget to the blog post editor (drag-and-drop or click-to-upload)
- Images upload to Supabase Storage and the URL is saved to `image_url`
- Show image preview in the editor

### 3B. Draft Preview Mode
- Add a "Preview" button in the blog post editor that opens a modal or side panel
- Renders the post exactly as it would look on the public blog
- Includes the full reading experience (TOC, progress bar, related posts placeholder)

### 3C. Scheduled Publishing
- Add a new `scheduled_at` column to the `blog_posts` table (nullable timestamp)
- In the editor, add a "Schedule" option alongside "Publish now"
- Shows a date/time picker for scheduling
- A backend function (edge function) that runs on a schedule to publish posts whose `scheduled_at` has passed
- Visual indicator in the post list: "Scheduled for [date]"

---

## Phase 4 -- Analytics and API

### 4A. Post View Counter
- New `post_views` table to track views per post per day
- Increment view count on each blog post page load (debounced, one per session)
- Display view counts in the admin dashboard
- RLS: anyone can insert (anonymous tracking), only admins can read

### 4B. Analytics Dashboard Panel
- Replace the current basic dashboard with richer analytics
- Show view counts per post (bar chart using recharts, already installed)
- Top posts by views
- Views over time (line chart)
- Subscriber growth over time

### 4C. REST API Edge Function for Automated Posting
- Create a `blog-api` edge function with JWT-based API key authentication
- Endpoints:
  - `POST /` -- Create a new blog post (title, content, category, etc.)
  - `GET /` -- List posts (with optional filters)
  - `PUT /:id` -- Update a post
  - `DELETE /:id` -- Delete a post
- Authenticated via a custom API key stored as a secret
- Perfect for n8n/OpenClaw integration: automate post creation from RSS feeds, AI-generated content, etc.
- Returns JSON responses with proper error handling

---

## Technical Details

### New Dependencies
- `react-helmet-async` -- dynamic meta tags and SEO
- `highlight.js` -- code syntax highlighting

### New Database Changes (on YOUR Supabase)
You will need to run SQL on your own Supabase dashboard for:

1. **Scheduled publishing column**:
```sql
ALTER TABLE public.blog_posts
ADD COLUMN scheduled_at timestamptz DEFAULT NULL;
```

2. **Post views table**:
```sql
CREATE TABLE public.post_views (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid NOT NULL REFERENCES public.blog_posts(id) ON DELETE CASCADE,
  viewed_at date NOT NULL DEFAULT CURRENT_DATE,
  view_count integer NOT NULL DEFAULT 1,
  UNIQUE(post_id, viewed_at)
);

ALTER TABLE public.post_views ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can increment views"
  ON public.post_views FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can update view count"
  ON public.post_views FOR UPDATE
  USING (true);

CREATE POLICY "Admins can read views"
  ON public.post_views FOR SELECT
  USING (public.has_role(auth.uid(), 'admin'));
```

3. **Storage bucket for images**:
```sql
INSERT INTO storage.buckets (id, name, public)
VALUES ('blog-images', 'blog-images', true);

CREATE POLICY "Admins can upload images"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'blog-images' AND public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Anyone can view blog images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'blog-images');
```

### New/Modified Files

```text
-- Phase 1
src/components/SEOHead.tsx              (new - dynamic meta tags)
src/components/ReadingProgress.tsx       (new - scroll progress bar)
src/components/TableOfContents.tsx       (new - auto-generated TOC)
src/components/RelatedPosts.tsx          (new - related posts section)
src/pages/BlogPost.tsx                   (enhanced - TOC, progress, related, SEO)

-- Phase 2
src/components/BlogSection.tsx           (enhanced - search bar)
src/components/CodeBlock.tsx             (new - syntax highlighted code)
src/pages/BlogPost.tsx                   (enhanced - better markdown, images, blockquotes)
src/index.css                            (enhanced - new animations, typography)

-- Phase 3
src/components/admin/BlogPostsPanel.tsx  (enhanced - image upload, draft preview, scheduling)
src/components/admin/ImageUploader.tsx   (new - drag-drop image upload)
src/components/admin/PostPreview.tsx     (new - draft preview modal)

-- Phase 4
src/components/admin/DashboardPanel.tsx  (enhanced - analytics charts)
src/components/admin/AnalyticsCharts.tsx (new - recharts visualizations)
src/pages/BlogPost.tsx                   (enhanced - view tracking)
supabase/functions/blog-api/index.ts     (new - REST API edge function)
```

### Edge Function: blog-api
- Secured with an API key (stored as a Supabase secret `BLOG_API_KEY`)
- Uses the Supabase service role key to bypass RLS for automated operations
- Validates incoming data (required fields, slug format, valid category)
- Returns proper HTTP status codes and JSON responses
- Example n8n/OpenClaw usage:
  ```
  POST https://ppmhntfohxjcqyzfbpui.supabase.co/functions/v1/blog-api
  Headers: { "Authorization": "Bearer YOUR_API_KEY" }
  Body: { "title_nl": "...", "content_nl": "...", "category": "ai", ... }
  ```

### Implementation Order
All 4 phases will be implemented sequentially in the order listed. Each phase builds on the previous one. I will provide you the SQL to run on your Supabase instance before implementing features that depend on database changes.

