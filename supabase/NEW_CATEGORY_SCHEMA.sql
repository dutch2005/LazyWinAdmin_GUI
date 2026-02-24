-- ==========================================
-- Mycka Amalia Chronicles - Category Schema
-- ==========================================

-- 1. Remove old check constraint
ALTER TABLE public.blog_posts 
DROP CONSTRAINT IF EXISTS blog_posts_category_check;

-- 2. Add new check constraint including Mycka Amalia Chronicles
ALTER TABLE public.blog_posts
ADD CONSTRAINT blog_posts_category_check 
CHECK (category IN ('ai', 'news', 'tutorials', 'tools', 'mycka-amalia'));

-- NOTE: If you need to add more fields later, use:
-- ALTER TABLE public.blog_posts ADD COLUMN IF NOT EXISTS new_field_name TEXT;
