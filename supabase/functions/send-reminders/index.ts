// Deploy: npx supabase functions deploy send-reminders
// Set secrets: npx supabase secrets set RESEND_API_KEY=re_xxx

import { createClient } from "npm:@supabase/supabase-js@2";

// Map interval to details
const REMINDERS = {
  "1w": {
    minDays: 7,
    maxDays: 8,
    subject: "hey, still there? / hey, ben je er nog?",
    html: (token: string, supabaseUrl: string) => `
<div style="font-family:-apple-system,sans-serif;color:#333;">
  <p>hey!</p>
  <p>I noticed you haven't dropped by the blog since signing up. just wanted to check if my welcome email landed in your spam folder? we've had some fun new posts about AI tools and automation recently.</p>
  <p><a href="https://mikemaze.nl?ut=${token}">Check them out here</a>.</p>
  <br/>
  <p>--</p>
  <p>hey!</p>
  <p>Ik zag dat je nog niet op de blog bent geweest sinds je aanmelding. Ik wilde even checken of mijn welkomstmail misschien in je spam terecht is gekomen? We hebben onlangs wat toffe nieuwe artikelen gepost over AI-tools en automatisering.</p>
  <p><a href="https://mikemaze.nl?ut=${token}">Bekijk ze hier</a>.</p>
  <br/>
  <p>Mike</p>
  <p style="font-size:12px;color:#888;">
    <a href="https://mikemaze.nl/unsubscribe?token=${token}">Unsubscribe / Afmelden</a>
  </p>
  <img src="${supabaseUrl}/functions/v1/track-open?t=${token}" width="1" height="1" style="display:none" />
</div>
    `,
  },
  "1m": {
    minDays: 30,
    maxDays: 32,
    subject: "a month already? here's what you missed / alweer een maand? dit heb je gemist",
    html: (token: string, supabaseUrl: string) => `
<div style="font-family:-apple-system,sans-serif;color:#333;">
  <p>Hi there,</p>
  <p>It's been about a month since we last saw you. Time flies! If you're interested in speeding up your workflow, I recently wrote a deep-dive on developer tools and AI automation that might be right up your alley.</p>
  <p>Come <a href="https://mikemaze.nl?ut=${token}">take a look</a> when you have a spare coffee break.</p>
  <br/>
  <p>--</p>
  <p>Hoi,</p>
  <p>Het is alweer een maandje geleden dat we je voor het laatst zagen. De tijd vliegt! Als je geïnteresseerd bent in het versnellen van je workflow: ik heb recent een deep-dive geschreven over developer tools en AI-automatisering die je vast interessant vindt.</p>
  <p>Kom <a href="https://mikemaze.nl?ut=${token}">gerust even kijken</a> tijdens je volgende koffiepauze.</p>
  <br/>
  <p>Mike</p>
  <p style="font-size:12px;color:#888;">
    <a href="https://mikemaze.nl/unsubscribe?token=${token}">Unsubscribe / Afmelden</a>
  </p>
  <img src="${supabaseUrl}/functions/v1/track-open?t=${token}" width="1" height="1" style="display:none" />
</div>
    `,
  },
  "3m": {
    minDays: 90,
    maxDays: 93,
    subject: "checking in on you / even inchecken",
    html: (token: string, supabaseUrl: string) => `
<div style="font-family:-apple-system,sans-serif;color:#333;">
  <p>Hi,</p>
  <p>It's been a few months! I wanted to personally reach out and ask what kind of content would be most valuable to you right now. Feel free to just reply to this email.</p>
  <p>In the meantime, here is <a href="https://mikemaze.nl?ut=${token}">the best post of the quarter</a>.</p>
  <br/>
  <p>--</p>
  <p>Hoi,</p>
  <p>Het is alweer een paar maanden geleden! Ik wilde even persoonlijk contact opnemen om te vragen welk type artikelen momenteel het meest waardevol voor je zouden zijn. Je kunt gewoon reageren op deze e-mail.</p>
  <p>In de tussentijd is hier <a href="https://mikemaze.nl?ut=${token}">het beste artikel van dit kwartaal</a>.</p>
  <br/>
  <p>Mike</p>
  <p style="font-size:12px;color:#888;">
    <a href="https://mikemaze.nl/unsubscribe?token=${token}">Unsubscribe / Afmelden</a>
  </p>
  <img src="${supabaseUrl}/functions/v1/track-open?t=${token}" width="1" height="1" style="display:none" />
</div>
    `,
  },
  "6m": {
    minDays: 180,
    maxDays: 185,
    subject: "honestly? I miss having you around / eerlijk gezegd mis ik je hier wel",
    html: (token: string, supabaseUrl: string) => `
<div style="font-family:-apple-system,sans-serif;color:#333;">
  <p>Hey,</p>
  <p>Honestly? I miss having you around. It's been half a year since you stopped by. There's zero pressure, but the door is always open if you want to catch up on the latest in tech.</p>
  <p><a href="https://mikemaze.nl?ut=${token}">See what's new</a>.</p>
  <br/>
  <p>--</p>
  <p>Hey,</p>
  <p>Eerlijk gezegd mis ik je hier wel een beetje. Het is alweer een half jaar geleden dat je langskwam. Voel je totaal niet verplicht, maar de deur staat altijd open als je wilt bijpraten over de nieuwste tech-ontwikkelingen.</p>
  <p><a href="https://mikemaze.nl?ut=${token}">Bekijk wat er nieuw is</a>.</p>
  <br/>
  <p>Mike</p>
  <p style="font-size:12px;color:#888;">
    <a href="https://mikemaze.nl/unsubscribe?token=${token}">Unsubscribe / Afmelden</a>
  </p>
  <img src="${supabaseUrl}/functions/v1/track-open?t=${token}" width="1" height="1" style="display:none" />
</div>
    `,
  },
  "1y": {
    minDays: 365,
    maxDays: 370,
    subject: "ok it's been a whole year. I had to say something. / oké het is een vol jaar. Ik moest even iets zeggen.",
    html: (token: string, supabaseUrl: string) => `
<div style="font-family:-apple-system,sans-serif;color:#333;">
  <p>Wow,</p>
  <p>It's officially been a whole year. I know, these automated emails can get absurd, but I had to acknowledge the milestone! If you're completely done with IT adventures, no hard feelings—you can easily unsubscribe below. Otherwise, I'd love to see you back on the site.</p>
  <p><a href="https://mikemaze.nl?ut=${token}">Drop by to say hi</a>.</p>
  <br/>
  <p>--</p>
  <p>Wow,</p>
  <p>Het is officieel een heel jaar geleden. Ik weet het, deze automatische mailtjes kunnen soms wat absurd worden, maar ik wilde deze mijlpaal toch even aantippen! Als je helemaal klaar bent met IT-avonturen, even goede vrienden—je kunt je hieronder makkelijk afmelden. Anders zou ik het tof vinden je weer eens op de site te zien.</p>
  <p><a href="https://mikemaze.nl?ut=${token}">Kom gerust even hallo zeggen</a>.</p>
  <br/>
  <p>Mike</p>
  <p style="font-size:12px;color:#888;">
    <a href="https://mikemaze.nl/unsubscribe?token=${token}">Unsubscribe / Afmelden</a>
  </p>
  <img src="${supabaseUrl}/functions/v1/track-open?t=${token}" width="1" height="1" style="display:none" />
</div>
    `,
  },
};

Deno.serve(async (req: Request) => {
  // Enforce service role auth (usually called via pg_cron with Bearer token)
  const authHeader = req.headers.get("Authorization");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const resendKey = Deno.env.get("RESEND_API_KEY");

  if (!authHeader || !serviceRoleKey || !supabaseUrl || authHeader !== `Bearer ${serviceRoleKey}`) {
    return new Response("Unauthorized", { status: 401 });
  }

  if (!resendKey) {
    return new Response("Missing RESEND_API_KEY", { status: 500 });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);

  // Fetch all subscribers
  const { data: subscribers, error: dbError } = await supabase
    .from("newsletter_subscribers")
    .select("id, email, unsubscribe_token, last_active_at, reminders_sent");

  if (dbError || !subscribers) {
    console.error("Error fetching subscribers:", dbError);
    return new Response(JSON.stringify({ error: "DB fetch error" }), { status: 500 });
  }

  const now = new Date();
  let sentCount = 0;
  let errorCount = 0;

  for (const sub of subscribers) {
    try {
      if (!sub.last_active_at) continue;

      const lastActive = new Date(sub.last_active_at);
      const diffTime = Math.abs(now.getTime() - lastActive.getTime());
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

      const remindersSent = sub.reminders_sent || [];

      // Determine matching bucket
      let targetInterval: string | null = null;
      for (const [interval, config] of Object.entries(REMINDERS)) {
        if (diffDays >= config.minDays && diffDays <= config.maxDays) {
          if (!remindersSent.includes(interval)) {
            targetInterval = interval;
            break;
          }
        }
      }

      if (targetInterval) {
        const config = REMINDERS[targetInterval as keyof typeof REMINDERS];

        // Send email
        const emailPayload = {
          from: "Mike Maze <newsletter@mikemaze.nl>",
          to: [sub.email],
          subject: config.subject,
          html: config.html(sub.unsubscribe_token, supabaseUrl),
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
          throw new Error(`Resend Error: ${resendRes.status} ${await resendRes.text()}`);
        }

        // Update subscriber jsonb
        const newRemindersSent = [...remindersSent, targetInterval];
        await supabase
          .from("newsletter_subscribers")
          .update({ reminders_sent: newRemindersSent })
          .eq("id", sub.id);

        // Audit log
        await supabase
          .from("reminder_log")
          .insert({ subscriber_id: sub.id, interval: targetInterval });

        sentCount++;
      }

    } catch (err) {
      console.error(`Error processing subscriber ${sub.email}:`, err);
      errorCount++;
    }
  }

  return new Response(
    JSON.stringify({ success: true, sentCount, errorCount }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  );
});
