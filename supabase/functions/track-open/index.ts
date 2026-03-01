// Deploy: npx supabase functions deploy track-open

import { createClient } from "npm:@supabase/supabase-js@2";

// 1x1 transparent GIF
const TRANSPARENT_GIF = new Uint8Array([
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00,
  0xff, 0xff, 0xff, 0x21, 0xf9, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x2c, 0x00, 0x00, 0x00, 0x00,
  0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x01, 0x44, 0x00, 0x3b
]);

Deno.serve(async (req: Request) => {
  // Always return the GIF silently, regardless of errors
  const url = new URL(req.url);
  const token = url.searchParams.get("t");

  if (token && req.method === "GET") {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (supabaseUrl && serviceRoleKey) {
      try {
        const supabase = createClient(supabaseUrl, serviceRoleKey);
        // Only update if the token exists, ignore errors
        await supabase
          .from("newsletter_subscribers")
          .update({ last_email_open_at: new Date().toISOString() })
          .eq("unsubscribe_token", token);
      } catch (err) {
        console.error("track-open error:", err);
      }
    }
  }

  return new Response(TRANSPARENT_GIF, {
    status: 200,
    headers: {
      "Content-Type": "image/gif",
      "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
      "Pragma": "no-cache",
      "Expires": "0",
    },
  });
});
