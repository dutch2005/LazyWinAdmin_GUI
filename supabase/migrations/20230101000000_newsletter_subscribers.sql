CREATE TABLE IF NOT EXISTS newsletter_subscribers (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  email text UNIQUE NOT NULL,
  unsubscribe_token uuid DEFAULT gen_random_uuid() NOT NULL,
  subscribed_at timestamptz DEFAULT now()
);

-- RLS: Only allow read/write from authenticated service roles (Edge functions)
ALTER TABLE newsletter_subscribers ENABLE ROW LEVEL SECURITY;
