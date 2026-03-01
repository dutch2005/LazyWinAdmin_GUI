-- Ensure extensions for scheduling and HTTP requests
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Add tracking columns
ALTER TABLE public.newsletter_subscribers
  ADD COLUMN IF NOT EXISTS last_visit_at timestamptz,
  ADD COLUMN IF NOT EXISTS last_email_open_at timestamptz,
  ADD COLUMN IF NOT EXISTS reminders_sent jsonb DEFAULT '[]'::jsonb;

-- Add the generated column last_active_at
-- It will be the most recent of last_visit_at, last_email_open_at, or created_at
ALTER TABLE public.newsletter_subscribers
  ADD COLUMN IF NOT EXISTS last_active_at timestamptz
  GENERATED ALWAYS AS (GREATEST(last_visit_at, last_email_open_at, created_at)) STORED;

-- Create reminder audit log table
CREATE TABLE IF NOT EXISTS public.reminder_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subscriber_id uuid REFERENCES public.newsletter_subscribers(id) ON DELETE CASCADE NOT NULL,
  interval text NOT NULL CHECK (interval IN ('1w', '1m', '3m', '6m', '1y')),
  sent_at timestamptz NOT NULL DEFAULT now()
);

-- Enable RLS for reminder_log
ALTER TABLE public.reminder_log ENABLE ROW LEVEL SECURITY;

-- Only admins can read reminder logs
CREATE POLICY "Admins can read reminder logs"
  ON public.reminder_log FOR SELECT
  TO authenticated
  USING (public.has_role(auth.uid(), 'admin'));

-- Only admins can insert reminder logs
CREATE POLICY "Admins can insert reminder logs"
  ON public.reminder_log FOR INSERT
  TO authenticated
  WITH CHECK (public.has_role(auth.uid(), 'admin'));

-- Set up the daily cron job
SELECT cron.schedule(
  'daily-re-engagement',
  '0 9 * * *',
  $$SELECT net.http_post(
    url := 'https://ppmhntfohxjcqyzfbpui.supabase.co/functions/v1/send-reminders',
    headers := json_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.service_role_key', true)
    )::jsonb,
    body := '{}'::jsonb
  )$$
);
