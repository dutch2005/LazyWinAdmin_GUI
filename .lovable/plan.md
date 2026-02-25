

# Plan: Security Fixes + Publish

## Security Scan Results

The scan found 6 issues. Here's how each will be addressed:

---

### 1. Enable Leaked Password Protection (warn)
Use the auth configuration tool to enable leaked password protection, which checks passwords against known breach databases during signup/login.

### 2–3. "Exposed Sensitive Data" on contact_messages & newsletter_subscribers (error)
These are **false positives**. Both tables already have restrictive admin-only SELECT policies. No public read access exists. These findings will be marked as ignored with explanation.

### 4–5. Missing UPDATE policies on contact_messages & newsletter_subscribers (warn)
**Fix**: Add a database migration that explicitly denies all UPDATE operations on both tables. These tables should be append-only (subscribers subscribe, messages get sent — neither should ever be modified).

```sql
-- Deny all updates on contact_messages (append-only)
CREATE POLICY "No updates allowed on contact messages"
  ON public.contact_messages FOR UPDATE
  USING (false);

-- Deny all updates on newsletter_subscribers (append-only)
CREATE POLICY "No updates allowed on newsletter subscribers"
  ON public.newsletter_subscribers FOR UPDATE
  USING (false);
```

### 6. Unpublished/Scheduled Blog Posts Could Leak (info)
The current RLS policy `Published posts are public` already restricts SELECT to `published = true`. However, **scheduled posts** (published but future-dated) are only filtered client-side with `.lte("date", ...)`. A savvy user could bypass this.

**Fix**: Update the blog_posts RLS policy to also enforce server-side date filtering:

```sql
-- Drop and recreate the public SELECT policy to include date check
DROP POLICY "Published posts are public" ON public.blog_posts;
CREATE POLICY "Published posts are public"
  ON public.blog_posts FOR SELECT
  USING (published = true AND date <= CURRENT_DATE);
```

This ensures scheduled posts are invisible at the database level, regardless of client-side manipulation.

### 7. HTML Content Sanitization (not flagged, but critical)
The `BlogPost.tsx` page renders WYSIWYG content using `dangerouslySetInnerHTML`. While blog content is admin-authored, sanitizing it adds defense-in-depth.

**Fix**: Install `dompurify` and sanitize HTML before rendering in `BlogPost.tsx` (line 240).

---

## Summary of Changes

| File / Resource | Change |
|---|---|
| Database migration | Add UPDATE-deny policies on `contact_messages` and `newsletter_subscribers`; update blog_posts SELECT policy to enforce `date <= CURRENT_DATE` |
| Auth config | Enable leaked password protection |
| `src/pages/BlogPost.tsx` | Sanitize HTML content with DOMPurify before `dangerouslySetInnerHTML` |
| `package.json` | Add `dompurify` + `@types/dompurify` |
| Security findings | Dismiss false positives for contact_messages and newsletter_subscribers "exposed data" findings |

**Files modified:** 2 (`BlogPost.tsx`, `package.json`)
**Database changes:** 1 migration (3 policy changes)
**Auth config:** 1 change (leaked password protection)

