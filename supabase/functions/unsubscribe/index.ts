import { createClient } from "npm:@supabase/supabase-js@2";

const ALLOWED_ORIGINS = ["https://mikemaze.nl", "http://localhost:8080"];

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

  try {
    const { token } = await req.json();

    if (!token) {
      return jsonResponse({ error: "No token provided" }, 400, origin);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing Supabase environment variables");
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { error } = await supabase
      .from("newsletter_subscribers")
      .delete()
      .eq("unsubscribe_token", token);

    if (error) {
      throw error;
    }

    return jsonResponse({ message: "Successfully unsubscribed" }, 200, origin);
  } catch (error) {
    console.error("Unsubscribe error:", error);
    return jsonResponse({ error: "Failed to unsubscribe" }, 500, origin);
  }
});
