# Plan: Scheduled Badge + WYSIWYG Editor for Admin Panel

## 1. Scheduled Badge in Blog Post List

In `BlogPostsPanel.tsx`, add a "scheduled" indicator next to the publish status for posts where `published === true` and `date > today`. This tells you at a glance which posts are live but time-gated. Make sure the date is checked both on the client as on the server, so those who change their time locally can not read future blog posts.

**Change in `BlogPostsPanel.tsx` (list view, around line 165):**

- After the existing published/concept badge, add a conditional "⏱ scheduled" badge in amber/orange when `post.published && post.date > new Date().toISOString().split('T')[0]`

---

## 2. WYSIWYG Rich Text Editor

Add a 2nd option (button to swap between the 2 options) next to the current Markdown `<textarea>` editor with a proper WYSIWYG editor using **Tiptap** (the leading open-source rich text editor for React, built on ProseMirror). This way you can use code text edit or using the WYSIWYG.

### Why Tiptap

- Modular extension system: only include what you need
- First-class React support via `@tiptap/react`
- Image handling, font size, text alignment, and resize all available as extensions
- Outputs HTML — your blog renderer already uses `dangerouslySetInnerHTML`, so it's compatible
- Free and open-source core

### New Dependencies

- `@tiptap/react` — React bindings
- `@tiptap/starter-kit` — Bold, italic, headings, lists, code blocks, blockquote, horizontal rule
- `@tiptap/extension-image` — Insert and display images
- `@tiptap/extension-link` — Clickable links
- `@tiptap/extension-text-align` — Left/center/right alignment
- `@tiptap/extension-underline` — Underline formatting
- `@tiptap/extension-placeholder` — Placeholder text
- `@tiptap/extension-text-style` + `@tiptap/extension-font-size` — Font size control

### Files Changed

#### New: `src/components/admin/RichTextEditor.tsx`

A new WYSIWYG editor component that replaces `MarkdownEditor` in the blog post form. Features:

- **Toolbar**: Bold, Italic, Underline, Strikethrough | H1, H2, H3 | Bullet list, Ordered list | Text align (left/center/right) | Link, Image (URL prompt) | Code block | Horizontal rule | Font size selector
- **Editor area**: Tiptap `EditorContent` with styled prose output
- **Props**: `value: string` (HTML), `onChange: (html: string) => void`, `placeholder?: string`
- The editor reads/writes HTML strings, keeping the same interface as the current MarkdownEditor

#### Modified: `src/components/admin/BlogPostsPanel.tsx`

1. **Scheduled badge** (line ~165): Add amber "⏱ scheduled" badge for future-dated published posts
2. **Import change**: Replace `MarkdownEditor` import with `RichTextEditor`
3. **Editor swap** (lines 219, 228): Replace `<MarkdownEditor>` with `<RichTextEditor>` for both NL and EN content tabs
4. **Category dropdown** (line 114): Add "mycka-amalia" to the category options so it appears in the select

#### Modified: `src/index.css`

Add minimal Tiptap editor styles (`.tiptap-editor` class) for the editing area — cursor, focus ring, image sizing, paragraph spacing.

### Data Compatibility Note

The blog content is currently stored as Markdown in the database. The WYSIWYG editor works with HTML. Two approaches:

**Option A — HTML going forward**: New posts use HTML. Existing Markdown posts will render fine since the `BlogPost.tsx` page already has a Markdown renderer. The WYSIWYG editor will show raw Markdown for old posts (not ideal for editing old content, but fine for new content).

**Option B — Convert existing**: Add a one-time migration or conversion utility to turn existing Markdown content into HTML.

I recommend **Option A** — simpler, no data migration, and old posts still render correctly on the public site. The `BlogPost.tsx` renderer can detect whether content is HTML or Markdown and render accordingly (check if content starts with `<` tags).  
  
Offer an option to individually convert pages from Markdown to HTML, do show a warning button that once converted it will not be converted.

### Architecture

```text
BlogPostsPanel
  ├── List View (+ scheduled badge)
  └── Edit/New View
        ├── NL tab → RichTextEditor (HTML)
        └── EN tab → RichTextEditor (HTML)

BlogPost.tsx (public page)
  └── Detect content type:
        ├── Starts with HTML tags → render as HTML
        └── Otherwise → use existing Markdown renderer
```

---

## Technical Details

- **Tiptap** is ~50KB gzipped for the core + starter kit, well within budget
- The `MarkdownEditor.tsx` file is preserved (not deleted) in case it's useful elsewhere
- The `RichTextEditor` component will match the existing editor's visual style (dark card, border, toolbar) so it fits the admin panel aesthetic
- Image insertion prompts for a URL (same as current link behavior). A future enhancement could add file upload via storage buckets
- Font size uses a dropdown with preset sizes (12, 14, 16, 18, 20, 24, 28, 32px)