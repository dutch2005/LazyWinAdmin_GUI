import { useState } from "react";
import { useLanguage } from "@/contexts/LanguageContext";
import { Mail, Send } from "lucide-react";
import { z } from "zod";

const emailSchema = z.string().trim().email().max(255);

const SUPABASE_URL =
  import.meta.env.VITE_EXTERNAL_SUPABASE_URL || import.meta.env.VITE_SUPABASE_URL;
const SUPABASE_ANON_KEY =
  import.meta.env.VITE_EXTERNAL_SUPABASE_ANON_KEY || import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY;

export const NewsletterSection = () => {
  const { t } = useLanguage();
  const [email, setEmail] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const result = emailSchema.safeParse(email);
    if (!result.success) return;

    setLoading(true);
    setErrorMsg(null);

    try {
      const res = await fetch(`${SUPABASE_URL}/functions/v1/subscribe`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        },
        body: JSON.stringify({ email: email.trim().toLowerCase() }),
      });

      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data?.error ?? `HTTP ${res.status}`);
      }

      setSubmitted(true);
      setEmail("");
    } catch (err) {
      setErrorMsg(
        err instanceof Error ? err.message : "Er is iets misgegaan. Probeer het opnieuw."
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <section id="newsletter" className="py-24 bg-background border-t border-border relative overflow-hidden">
      {/* Background dot pattern */}
      <div className="absolute inset-0 dot-pattern opacity-20" />
      {/* Glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 rounded-full bg-primary/5 blur-3xl pointer-events-none" />

      <div className="relative z-10 container mx-auto px-4 text-center max-w-xl">
        <div className="inline-flex items-center justify-center w-16 h-16 rounded-xl bg-primary/10 border border-primary/30 mb-6 animate-pulse-cyan">
          <Mail className="w-7 h-7 text-primary" />
        </div>

        <span className="tag-category text-primary font-mono block mb-3">{t("newsletter.tag")}</span>
        <h2 className="text-3xl font-bold mb-4">{t("newsletter.title")}</h2>
        <p className="text-muted-foreground mb-8">{t("newsletter.desc")}</p>

        {submitted ? (
          <div className="flex items-center justify-center gap-2 text-primary font-semibold py-4 px-6 rounded-lg border border-primary/30 bg-primary/5 animate-fade-in">
            <Send className="w-4 h-4" />
            ✓ {" "}
            {t("newsletter.btn")}!
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            <form onSubmit={handleSubmit} className="flex gap-3">
              <input
                type="email"
                value={email}
                onChange={(e) => { setEmail(e.target.value); setErrorMsg(null); }}
                placeholder={t("newsletter.placeholder")}
                required
                className="flex-1 bg-card border border-border rounded-md px-4 py-3 text-foreground placeholder:text-muted-foreground focus:outline-none focus:border-primary/60 focus:ring-1 focus:ring-primary/30 transition-all font-sans"
              />
              <button
                type="submit"
                disabled={loading}
                className="bg-primary text-primary-foreground px-6 py-3 rounded-md font-semibold hover:opacity-90 transition-all glow-cyan flex items-center gap-2 whitespace-nowrap disabled:opacity-60"
              >
                {loading ? <span className="w-4 h-4 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin" /> : <Send className="w-4 h-4" />}
                {t("newsletter.btn")}
              </button>
            </form>
            {errorMsg && (
              <p className="text-sm text-destructive text-left px-1">{errorMsg}</p>
            )}
          </div>
        )}
      </div>
    </section>
  );
};
