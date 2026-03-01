# Instructions for Mike Maze IT Adventures
## 1. Supabase Deployment & Resend Secrets
If the automated deployment fails, please run the following commands manually to deploy the Edge Function:
```bash
npx supabase functions deploy subscribe
npx supabase functions deploy unsubscribe
npx supabase secrets set RESEND_API_KEY=re_xxx
```

## 4. Resend Email Sender Verification
To ensure email delivery, you must verify the domain `mikemaze.nl` in Resend.
- Add the sender `newsletter@mikemaze.nl` as a verified sender.
- Check your Resend dashboard for the specific DNS records (SPF, DKIM, DMARC) needed to configure `mikemaze.nl` with your domain registrar.

Since Supabase deployment requires authentication, I have added the manual deployment commands to `instructions.md`.
## 5. & 9. Database schema for Newsletter
If your local environment is authenticated with Supabase CLI, apply the database schema by running:
```bash
npx supabase db push
```
Alternatively, you can run the following SQL script directly in your Supabase SQL Editor to create the table required for subscriptions and unsubscriptions:

```sql
CREATE TABLE IF NOT EXISTS newsletter_subscribers (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  email text UNIQUE NOT NULL,
  unsubscribe_token uuid DEFAULT gen_random_uuid() NOT NULL,
  subscribed_at timestamptz DEFAULT now()
);

-- RLS: Only allow read/write from authenticated service roles (Edge functions)
ALTER TABLE newsletter_subscribers ENABLE ROW LEVEL SECURITY;
```
