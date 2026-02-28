/**
 * Generates public/sitemap.xml from all published blog posts in Supabase.
 * Usage: node scripts/generate-sitemap.mjs
 */
import https from "https";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Parse .env manually (no dotenv dependency needed)
const envPath = path.join(__dirname, "..", ".env");
const envText = fs.readFileSync(envPath, "utf-8");
const supabaseUrl = envText.match(/VITE_SUPABASE_URL="?([^"\n]+)"?/)?.[1]?.trim();
const supabaseKey = envText.match(/VITE_SUPABASE_PUBLISHABLE_KEY="?([^"\n]+)"?/)?.[1]?.trim();

if (!supabaseUrl) {
  console.error("VITE_SUPABASE_URL not found in .env");
  process.exit(1);
}
if (!supabaseKey) {
  console.error("VITE_SUPABASE_PUBLISHABLE_KEY not found in .env");
  process.exit(1);
}

const SITE_BASE = "https://mikemaze.nl";

// Parse the Supabase REST API hostname and path prefix from the URL
const parsedUrl = new URL(supabaseUrl);
const hostname = parsedUrl.hostname;
const apiPath = "/rest/v1/blog_posts?select=slug,date,updated_at&published=eq.true";

const options = {
  hostname,
  path: apiPath,
  method: "GET",
  headers: {
    "apikey": supabaseKey,
    "Authorization": `Bearer ${supabaseKey}`,
    "Accept": "application/json",
  },
};

console.log("Fetching published posts from Supabase...");

const req = https.request(options, (res) => {
  let data = "";
  res.on("data", (chunk) => (data += chunk));
  res.on("end", () => {
    if (res.statusCode !== 200) {
      console.error(`Supabase responded with HTTP ${res.statusCode}:`);
      console.error(data.slice(0, 500));
      process.exit(1);
    }

    let posts;
    try {
      posts = JSON.parse(data);
    } catch (e) {
      console.error("Failed to parse Supabase response:", e.message);
      console.error("Raw response:", data.slice(0, 500));
      process.exit(1);
    }

    if (!Array.isArray(posts)) {
      console.error("Unexpected response shape from Supabase:", JSON.stringify(posts).slice(0, 200));
      process.exit(1);
    }

    const today = new Date().toISOString().slice(0, 10);

    const urlEntries = [
      // Homepage
      `  <url>
    <loc>${SITE_BASE}/</loc>
    <changefreq>weekly</changefreq>
    <priority>1.0</priority>
  </url>`,
      // One entry per published post
      ...posts.map((post) => {
        const lastmod = post.updated_at
          ? post.updated_at.slice(0, 10)
          : (post.date || today);
        return `  <url>
    <loc>${SITE_BASE}/blog/${post.slug}</loc>
    <lastmod>${lastmod}</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>`;
      }),
    ];

    const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urlEntries.join("\n")}
</urlset>
`;

    const outPath = path.join(__dirname, "..", "public", "sitemap.xml");
    fs.writeFileSync(outPath, xml, "utf-8");

    const totalUrls = urlEntries.length;
    console.log(`Sitemap written to public/sitemap.xml — ${totalUrls} URL(s) (1 homepage + ${posts.length} post(s))`);
  });
});

req.on("error", (e) => {
  console.error("Request error:", e.message);
  process.exit(1);
});

req.end();
