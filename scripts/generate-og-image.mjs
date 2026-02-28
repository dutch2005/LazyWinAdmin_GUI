/**
 * Generates the OG social preview image using Google Imagen 3 via the Gemini API.
 * Usage: node scripts/generate-og-image.mjs
 */
import https from "https";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Parse .env manually (no dotenv dependency needed)
const envPath = path.join(__dirname, "..", ".env");
const envText = fs.readFileSync(envPath, "utf-8");
const apiKey = envText.match(/GEMINI_AI_KEY="?([^"\n]+)"?/)?.[1]?.trim();

if (!apiKey) {
  console.error("❌  GEMINI_AI_KEY not found in .env");
  process.exit(1);
}

const prompt = `
Transparent background, no background fill whatsoever, fully transparent PNG-style image.

Glowing cyan text "Mike Maze" large and bold, gradient from #00d4ff to #0ea5e9, with a soft cyan outer glow/bloom effect around the letters.
Below that, white semi-transparent text "IT Adventures" medium size, also with subtle glow.
Below that, muted gray monospace text "mikemaze.nl".
Abstract circuit board lines and nodes radiating outward from the text, very low opacity, cyan color.
The entire composition floats on a transparent background — no dark fill, no solid background, no border box.
Cyberpunk terminal aesthetic. Clean, minimal, glowing.
No people, no faces, no logos of other companies.
`.trim();

const body = JSON.stringify({
  instances: [{ prompt }],
  parameters: {
    sampleCount: 1,
    aspectRatio: "16:9",
    safetyFilterLevel: "block_only_high",
    outputOptions: {
      mimeType: "image/png",
    },
  },
});

const options = {
  hostname: "generativelanguage.googleapis.com",
  path: `/v1beta/models/imagen-4.0-ultra-generate-001:predict?key=${apiKey}`,
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "Content-Length": Buffer.byteLength(body),
  },
};

console.log("🎨  Calling Imagen 3 to generate OG image...");

const req = https.request(options, (res) => {
  let data = "";
  res.on("data", (chunk) => (data += chunk));
  res.on("end", () => {
    try {
      const json = JSON.parse(data);
      const b64 = json.predictions?.[0]?.bytesBase64Encoded;
      if (b64) {
        const buf = Buffer.from(b64, "base64");
        const outPath = path.join(__dirname, "..", "public", "brand.png");
        fs.writeFileSync(outPath, buf);
        console.log(`✅  Saved to public/brand.png (${(buf.length / 1024).toFixed(1)} KB)`);
      } else {
        console.error("❌  Unexpected API response:");
        console.error(JSON.stringify(json, null, 2));
      }
    } catch (e) {
      console.error("❌  Parse error:", e.message);
      console.error("Raw response:", data.slice(0, 500));
    }
  });
});

req.on("error", (e) => console.error("❌  Request error:", e.message));
req.write(body);
req.end();
