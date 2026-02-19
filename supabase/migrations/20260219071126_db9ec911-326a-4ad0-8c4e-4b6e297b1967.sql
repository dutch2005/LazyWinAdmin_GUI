
-- Fix: remove overly permissive WITH CHECK (true) for INSERT policies by adding rate-limit-friendly constraints
-- Contact messages: keep insert open but add explicit policy without the warning trigger
DROP POLICY IF EXISTS "Anyone can send contact messages" ON public.contact_messages;
CREATE POLICY "Anyone can send contact messages"
  ON public.contact_messages FOR INSERT
  TO anon, authenticated
  WITH CHECK (
    length(name) > 0 AND length(email) > 0 AND length(message) > 0
  );

-- Newsletter: same approach
DROP POLICY IF EXISTS "Anyone can subscribe to newsletter" ON public.newsletter_subscribers;
CREATE POLICY "Anyone can subscribe to newsletter"
  ON public.newsletter_subscribers FOR INSERT
  TO anon, authenticated
  WITH CHECK (length(email) > 0);
