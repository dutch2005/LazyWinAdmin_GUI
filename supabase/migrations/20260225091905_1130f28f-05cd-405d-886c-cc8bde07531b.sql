
-- Deny all updates on contact_messages (append-only)
CREATE POLICY "No updates allowed on contact messages"
  ON public.contact_messages FOR UPDATE
  USING (false);

-- Deny all updates on newsletter_subscribers (append-only)
CREATE POLICY "No updates allowed on newsletter subscribers"
  ON public.newsletter_subscribers FOR UPDATE
  USING (false);

-- Harden blog_posts: enforce date filtering server-side
DROP POLICY "Published posts are public" ON public.blog_posts;
CREATE POLICY "Published posts are public"
  ON public.blog_posts FOR SELECT
  USING (published = true AND date <= CURRENT_DATE);
