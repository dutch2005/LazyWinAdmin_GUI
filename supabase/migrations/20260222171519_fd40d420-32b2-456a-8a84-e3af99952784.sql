-- Admin can delete contact messages (spam cleanup)
CREATE POLICY "Admins can delete contact messages"
  ON public.contact_messages FOR DELETE
  TO authenticated
  USING (public.has_role(auth.uid(), 'admin'));

-- Admin can delete newsletter subscribers
CREATE POLICY "Admins can delete newsletter subscribers"
  ON public.newsletter_subscribers FOR DELETE
  TO authenticated
  USING (public.has_role(auth.uid(), 'admin'));

-- Add email format check constraint on newsletter_subscribers
ALTER TABLE public.newsletter_subscribers
  ADD CONSTRAINT newsletter_email_format
  CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- Add email format check constraint on contact_messages
ALTER TABLE public.contact_messages
  ADD CONSTRAINT contact_email_format
  CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');