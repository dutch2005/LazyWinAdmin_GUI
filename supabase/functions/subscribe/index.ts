// Deploy: npx supabase functions deploy subscribe
// Set secrets: npx supabase secrets set RESEND_API_KEY=re_xxx
// Get Resend key free at: https://resend.com (free tier: 3000 emails/month)

import { createClient } from "npm:@supabase/supabase-js@2";

const ALLOWED_ORIGINS = ["https://mikemaze.nl", "http://localhost:8080"];

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const WELCOME_HTML = (email: string, unsubscribeToken: string, supabaseUrl: string) => `<!DOCTYPE html>
<html lang="nl">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Welkom bij Mike Maze IT Adventures</title>
</head>
<body style="margin:0;padding:0;background-color:#0a0a0f;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#ffffff;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color:#0a0a0f;">
    <tr>
      <td align="center" style="padding:48px 16px;">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width:560px;">

          <!-- Header / Logo area -->
          <tr>
            <td align="center" style="padding-bottom:32px;">
              <div style="display:inline-block;background:rgba(0,212,255,0.08);border:1px solid rgba(0,212,255,0.25);border-radius:12px;padding:16px 28px;">
                <span style="font-size:22px;font-weight:700;color:#00d4ff;letter-spacing:-0.5px;font-family:monospace;">Mike Maze</span>
                <span style="font-size:22px;font-weight:700;color:#ffffff;letter-spacing:-0.5px;"> IT Adventures</span>
              </div>
            </td>
          </tr>

          <!-- Main card -->
          <tr>
            <td style="background-color:#111118;border:1px solid rgba(255,255,255,0.08);border-radius:16px;padding:40px 36px;">

              <!-- Greeting -->
              <p style="margin:0 0 8px 0;font-size:13px;font-weight:600;color:#00d4ff;letter-spacing:0.08em;text-transform:uppercase;font-family:monospace;">Nieuwsbrief bevestiging</p>
              <h1 style="margin:0 0 20px 0;font-size:26px;font-weight:700;color:#ffffff;line-height:1.3;">Hallo! Welkom bij de<br/>Mike Maze IT Adventures nieuwsbrief.</h1>
              <p style="margin:0 0 24px 0;font-size:15px;line-height:1.7;color:#a0a0b0;">
                Super dat je erbij bent! Je ontvangt voortaan updates over de nieuwste ontwikkelingen in de tech-wereld, rechtstreeks in je inbox.
              </p>

              <!-- What to expect -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td style="background:rgba(0,212,255,0.06);border:1px solid rgba(0,212,255,0.15);border-radius:10px;padding:20px 24px;">
                    <p style="margin:0 0 12px 0;font-size:13px;font-weight:600;color:#00d4ff;text-transform:uppercase;letter-spacing:0.06em;font-family:monospace;">Wat kun je verwachten?</p>
                    <ul style="margin:0;padding:0 0 0 18px;font-size:14px;line-height:2;color:#c0c0d0;">
                      <li>Tech nieuws &amp; trends in plain language</li>
                      <li>AI automatisering — praktische tips &amp; tools</li>
                      <li>Tutorials &amp; deep-dives voor developers</li>
                      <li>Inzichten uit het dagelijks werk als IT-professional</li>
                    </ul>
                  </td>
                </tr>
              </table>

              <!-- CTA button -->
              <table role="presentation" cellspacing="0" cellpadding="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td align="center" style="background:linear-gradient(135deg,#00d4ff,#0099cc);border-radius:8px;">
                    <a href="https://mikemaze.nl?ut=${unsubscribeToken}" target="_blank" style="display:inline-block;padding:14px 32px;font-size:15px;font-weight:700;color:#0a0a0f;text-decoration:none;letter-spacing:0.02em;">Bezoek de blog &rarr;</a>
                  </td>
                </tr>
              </table>

              <!-- Divider -->
              <hr style="border:none;border-top:1px solid rgba(255,255,255,0.07);margin:0 0 24px 0;" />

              <!-- Closing -->
              <p style="margin:0 0 6px 0;font-size:15px;color:#a0a0b0;line-height:1.6;">
                Bedankt voor je vertrouwen. Tot snel!
              </p>
              <p style="margin:0;font-size:15px;font-weight:600;color:#ffffff;">Mike</p>
              <p style="margin:4px 0 0 0;font-size:13px;color:#00d4ff;font-family:monospace;">mikemaze.nl</p>

            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding-top:24px;">
              <p style="margin:0;font-size:12px;color:#555566;line-height:1.6;">
                Je ontvangt deze e-mail omdat ${email} zich heeft aangemeld voor de Mike Maze IT Adventures nieuwsbrief.<br/>
                Je kunt je altijd <a href="https://mikemaze.nl/unsubscribe?token=${unsubscribeToken}" style="color:#00d4ff;text-decoration:underline;">afmelden via deze link</a>.
              </p>
              <p style="margin:12px 0 0 0;font-size:12px;color:#444455;">
                &copy; ${new Date().getFullYear()} Mike Maze IT Adventures &bull; <a href="https://mikemaze.nl?ut=${unsubscribeToken}" style="color:#00d4ff;text-decoration:none;">mikemaze.nl</a>
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
  <img src="${supabaseUrl}/functions/v1/track-open?t=${unsubscribeToken}" width="1" height="1" style="display:none" />
</body>
</html>`;

function corsHeaders(origin: string | null): Record<string, string> {
  const allowedOrigin =
    origin && ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    "Access-Control-Allow-Origin": allowedOrigin,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  };
}

function jsonResponse(
  body: unknown,
  status: number,
  origin: string | null
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders(origin),
    },
  });
}

Deno.serve(async (req: Request) => {
  const origin = req.headers.get("origin");

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders(origin) });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405, origin);
  }

  // --- Parse & validate body ---
  let body: { email?: unknown };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400, origin);
  }

  const email =
    typeof body.email === "string" ? body.email.trim().toLowerCase() : "";

  if (!email || !EMAIL_REGEX.test(email) || email.length > 255) {
    return jsonResponse({ error: "Invalid email address" }, 400, origin);
  }

  // --- Supabase insert (service role bypasses RLS) ---
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    return jsonResponse({ error: "Server configuration error" }, 500, origin);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);

  const { data: insertedData, error: dbError } = await supabase
    .from("newsletter_subscribers")
    .insert({ email }).select('unsubscribe_token').single();

  if (dbError) {
    // Unique constraint violation — subscriber already exists, treat as success
    if (dbError.code === "23505") {
      return jsonResponse({ success: true, alreadySubscribed: true }, 200, origin);
    }
    console.error("DB insert error:", dbError);
    return jsonResponse({ error: "Database error" }, 500, origin);
  }

  // --- Send welcome email via Resend ---
  const resendKey = Deno.env.get("RESEND_API_KEY");

  if (!resendKey) {
    // DB insert succeeded; warn but don't fail the request
    console.warn("RESEND_API_KEY not set — welcome email skipped");
    return jsonResponse({ success: true, emailSkipped: true }, 200, origin);
  }

  const emailPayload = {
    from: "Mike Maze <newsletter@mikemaze.nl>",
    to: [email],
    subject: "Welkom bij Mike Maze IT Adventures! 🚀",
    html: WELCOME_HTML(email, insertedData.unsubscribe_token, supabaseUrl),
  };

  const resendRes = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${resendKey}`,
    },
    body: JSON.stringify(emailPayload),
  });

  if (!resendRes.ok) {
    const resendBody = await resendRes.text();
    console.error("Resend API error:", resendRes.status, resendBody);
    // Subscriber is already saved — don't surface the email failure to the user
    return jsonResponse({ success: true, emailError: "send_failed" }, 200, origin);
  }

  return jsonResponse({ success: true }, 200, origin);
});
