

# Plan: Add Image Upload to WYSIWYG Editor

The WYSIWYG editor currently only supports inserting images via URL prompt. This plan adds drag-and-drop and browse-to-upload support using Lovable Cloud file storage.

---

## Changes

### 1. Create Storage Bucket (Database Migration)

Create a public `blog-images` storage bucket with RLS policies allowing admins to upload/manage files and anyone to view them (since blog images are public).

```sql
INSERT INTO storage.buckets (id, name, public) VALUES ('blog-images', 'blog-images', true);

CREATE POLICY "Anyone can view blog images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'blog-images');

CREATE POLICY "Admins can upload blog images"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'blog-images' AND has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can delete blog images"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'blog-images' AND has_role(auth.uid(), 'admin'));
```

### 2. Update `src/components/admin/RichTextEditor.tsx`

- **Add a hidden file input** (`<input type="file" accept="image/*">`) triggered by the existing Image toolbar button
- **Add drag-and-drop support** on the editor area — listen for `drop` and `dragover` events on the editor wrapper
- **Upload handler**: When a file is selected or dropped, upload it to the `blog-images` bucket via the storage client, get the public URL, and insert it into the editor with `editor.chain().focus().setImage({ src: publicUrl }).run()`
- **Keep the URL prompt** as a fallback — show a small popover or modal with two options: "Upload file" and "Enter URL"
- **Upload progress**: Show a brief loading indicator (spinner or progress bar) while the image uploads
- **Import** `db` from `@/lib/supabaseClient` for the storage upload

### 3. Tiptap Drop Handler

Configure Tiptap's `editorProps.handleDrop` to intercept file drops directly in the editor content area. When an image file is dropped, upload it and insert at the drop position instead of the default browser behavior.

Also configure `handlePaste` so pasting images from clipboard works the same way.

---

## Technical Details

- Uses the external Supabase client (`db` from `supabaseClient.ts`) since that's where the blog data lives
- Files are stored with a unique name: `blog-images/{timestamp}-{filename}` to avoid collisions
- Public URL is constructed via `db.storage.from('blog-images').getPublicUrl(path)`
- Max file size: no enforced limit beyond the default (browser will handle very large files gracefully)
- Supported formats: any image type the browser accepts (`image/*`)

**Files modified:** 1 (`RichTextEditor.tsx`)
**Database changes:** 1 migration (create bucket + RLS policies)

