

# Plan: Add "Convert to HTML" Button for Markdown Posts

## Overview

Add a conversion button in the admin editor that converts existing Markdown content to HTML using a client-side Markdown-to-HTML converter. This enables old Markdown posts to be edited properly in the WYSIWYG editor. The public `BlogPost.tsx` page also needs to detect whether content is HTML or Markdown and render accordingly.

---

## Changes

### 1. `src/components/admin/BlogPostsPanel.tsx`

Add a "Convert to HTML" button that appears in the editor area when editing an existing post and the editor is in WYSIWYG mode. The button:

- Detects if the current content looks like Markdown (does not start with `<` tags)
- Shows an amber warning banner: "This content appears to be Markdown. Convert it to HTML for the WYSIWYG editor? This action cannot be undone."
- On click, shows a confirmation dialog (reuse the existing modal pattern with `AlertTriangle` icon)
- Converts `content_nl` and/or `content_en` from Markdown to HTML using a simple client-side converter function
- The converter handles: headings (`##`, `###`), bold (`**`), italic (`*`), links (`[text](url)`), lists (`- item`), code blocks (``` ``` ```), paragraphs, images (`![alt](url)`), and horizontal rules (`---`)

The conversion function will be defined in the same file (or a small utility). It does not need a library — a ~30-line regex-based converter matching the existing Markdown patterns used in the blog is sufficient.

### 2. `src/pages/BlogPost.tsx`

Add HTML content detection: if content starts with an HTML tag (e.g. `<p>`, `<h1>`, `<div>`, `<ul>`), render it directly with `dangerouslySetInnerHTML` inside a styled prose container. Otherwise, use the existing Markdown renderer.

This is a small conditional wrapper around lines 235-278.

---

## Technical Details

- Detection heuristic: `content.trimStart().startsWith('<')` — simple and reliable since Tiptap always outputs HTML starting with tags
- The Markdown-to-HTML converter is one-way and handles the subset of Markdown actually used in the blog posts
- No new dependencies needed
- The conversion button only appears for existing posts (not new ones) and only when content looks like Markdown
- Both NL and EN content tabs get their own convert button independently

**Files modified:** 2 (`BlogPostsPanel.tsx`, `BlogPost.tsx`)

