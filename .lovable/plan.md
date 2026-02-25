

# Fix: Hide Future-Dated Blog Posts

## Problem
The `BlogSection.tsx` already filters out future posts with `.lte("date", today)` — good. But `BlogPost.tsx` (the individual post page) fetches **all** published posts without a date filter. This means:

1. Future posts appear in the **prev/next navigation** at the bottom of any post
2. Future posts appear in **Related Posts**
3. Anyone who knows (or guesses) the slug can **directly access** a future post at `/blog/slug-name`

## Solution
Add the same `.lte("date", today)` filter to the query in `BlogPost.tsx`. This is a one-line change.

---

## Changes

### `src/pages/BlogPost.tsx` (line ~107)
Add `.lte("date", new Date().toISOString().split('T')[0])` to the fetch query, right after `.eq("published", true)`.

Before:
```typescript
.eq("published", true)
.order("date", { ascending: false });
```

After:
```typescript
.eq("published", true)
.lte("date", new Date().toISOString().split('T')[0])
.order("date", { ascending: false });
```

This ensures future-dated posts won't load on the individual post page, won't appear in prev/next navigation, and won't show in related posts — matching the behavior of the blog listing page.

**Files modified:** 1 (`BlogPost.tsx`)
No database changes needed.

