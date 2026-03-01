-- Add unsubscribe_token to newsletter_subscribers if it doesn't exist
ALTER TABLE newsletter_subscribers 
  ADD COLUMN IF NOT EXISTS unsubscribe_token uuid DEFAULT gen_random_uuid() NOT NULL;

-- Add subscribed_at alias if created_at is the only timestamp
ALTER TABLE newsletter_subscribers 
  ADD COLUMN IF NOT EXISTS subscribed_at timestamptz DEFAULT now();

-- Backfill subscribed_at from created_at for existing rows
UPDATE newsletter_subscribers SET subscribed_at = created_at WHERE subscribed_at IS NULL;
