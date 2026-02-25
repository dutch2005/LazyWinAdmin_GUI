

# Analysis: Empty Dutch Content on Blog Posts

## What's Happening

I investigated the blog post at `/blog/mycka-amalia-chronicles-01-bloodline`. The screenshot shows the Dutch title renders correctly, but the **content area is completely empty**. This is a **data issue** — the post was created with English content filled in, but the Dutch content field (`content_nl`) was left empty. The rendering code works correctly; it simply has nothing to display.

Currently when a language version has no content, the page shows a blank area — which is a poor user experience.

## Proposed Fix

### 1. `src/pages/BlogPost.tsx` — Add language fallback

When the selected language's content is empty, **fall back to the other language** and show a small banner informing the reader:

- If `content_nl` is empty but `content_en` has content, show the English content with a notice: "Dit artikel is alleen beschikbaar in het Engels."
- If `content_en` is empty but `content_nl` has content, show the Dutch content with a notice: "This article is only available in Dutch."
- Apply the same fallback logic to `title` and `excerpt` fields as well, so no part of the page is blank.

### 2. `src/components/admin/BlogPostsPanel.tsx` — Add missing content warning

In the post list view, show a small warning indicator when a post is missing content for one language (e.g., a flag icon or text like "⚠ NL missing" or "⚠ EN missing"). This helps the admin spot incomplete translations at a glance.

---

## Technical Details

The fallback logic in `BlogPost.tsx` (around lines 161-163) changes from:
```
const content = lang === "nl" ? post.content_nl : post.content_en;
```
to:
```
const contentRaw = lang === "nl" ? post.content_nl : post.content_en;
const fallbackContent = lang === "nl" ? post.content_en : post.content_nl;
const isFallback = (!contentRaw || !contentRaw.trim()) && fallbackContent?.trim();
const content = isFallback ? fallbackContent : contentRaw;
```

A small info banner renders above the content when `isFallback` is true.

**Files modified:** 2 (`BlogPost.tsx`, `BlogPostsPanel.tsx`)

