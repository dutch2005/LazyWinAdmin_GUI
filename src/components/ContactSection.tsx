import { useState } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { useLanguage } from "@/contexts/LanguageContext";
import { supabase } from "@/integrations/supabase/client";
import { Mail, MapPin, Linkedin, Send, CheckCircle } from "lucide-react";

const schema = z.object({
  name: z.string().trim().min(2, { message: "name_min" }).max(100),
  email: z.string().trim().email({ message: "email_invalid" }).max(255),
  subject: z.string().trim().min(3, { message: "subject_min" }).max(200),
  message: z.string().trim().min(10, { message: "message_min" }).max(2000),
});

type FormData = z.infer<typeof schema>;

export const ContactSection = () => {
  const { lang, t } = useLanguage();
  const [submitted, setSubmitted] = useState(false);
  const [serverError, setServerError] = useState("");

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
    reset,
  } = useForm<FormData>({ resolver: zodResolver(schema) });

  const errorMessages: Record<string, { nl: string; en: string }> = {
    name_min: { nl: "Naam moet minimaal 2 tekens zijn", en: "Name must be at least 2 characters" },
    email_invalid: { nl: "Voer een geldig e-mailadres in", en: "Enter a valid email address" },
    subject_min: { nl: "Onderwerp moet minimaal 3 tekens zijn", en: "Subject must be at least 3 characters" },
    message_min: { nl: "Bericht moet minimaal 10 tekens zijn", en: "Message must be at least 10 characters" },
  };

  const getError = (key: string | undefined) => {
    if (!key) return "";
    const msg = errorMessages[key];
    if (msg) return msg[lang];
    return key;
  };

  const onSubmit = async (data: FormData) => {
    setServerError("");
    const { error } = await supabase.from("contact_messages").insert({
      name: data.name,
      email: data.email,
      subject: data.subject,
      message: data.message,
    });

    if (error) {
      setServerError(lang === "nl" ? "Er is iets misgegaan. Probeer het later opnieuw." : "Something went wrong. Please try again later.");
      return;
    }

    setSubmitted(true);
    reset();
  };

  return (
    <section id="contact" className="py-24 bg-card border-t border-border">
      <div className="container mx-auto px-4">
        {/* Header */}
        <div className="mb-12">
          <span className="tag-category text-primary font-mono">// {lang === "nl" ? "contact" : "contact"}</span>
          <h2 className="text-4xl font-bold mt-2">{t("contact.title")}</h2>
          <p className="text-muted-foreground mt-3 max-w-xl">{t("contact.desc")}</p>
        </div>

        <div className="grid lg:grid-cols-2 gap-16">
          {/* Left: contact info */}
          <div className="space-y-8">
            <div>
              <h3 className="text-lg font-semibold mb-6">{t("contact.info.title")}</h3>
              <div className="space-y-4">
                {/* Email link — obfuscated to prevent bot scraping */}
                <a
                  href="mailto:dutch2005@xtremeweb.xyz"
                  className="flex items-center gap-4 p-4 card-glass rounded-xl group hover:border-primary/40 transition-colors"
                >
                  <div className="w-10 h-10 rounded-lg bg-primary/10 border border-primary/20 flex items-center justify-center flex-shrink-0 group-hover:bg-primary/20 transition-colors">
                    <Mail className="w-5 h-5 text-primary" />
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground font-mono">Email</p>
                    <p className="text-foreground font-medium" style={{ unicodeBidi: "bidi-override", direction: "rtl" }}>
                      zyx.bewemertxe@5002hctud
                    </p>
                  </div>
                </a>

                <a
                  href="https://www.linkedin.com/in/michael-maertzdorf-b9231420/"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-4 p-4 card-glass rounded-xl group hover:border-primary/40 transition-colors"
                >
                  <div className="w-10 h-10 rounded-lg bg-primary/10 border border-primary/20 flex items-center justify-center flex-shrink-0 group-hover:bg-primary/20 transition-colors">
                    <Linkedin className="w-5 h-5 text-primary" />
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground font-mono">LinkedIn</p>
                    <p className="text-foreground font-medium">Michael Maertzdorf</p>
                  </div>
                </a>

                <div className="flex items-center gap-4 p-4 card-glass rounded-xl">
                  <div className="w-10 h-10 rounded-lg bg-primary/10 border border-primary/20 flex items-center justify-center flex-shrink-0">
                    <MapPin className="w-5 h-5 text-primary" />
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground font-mono">{lang === "nl" ? "Locatie" : "Location"}</p>
                    <p className="text-foreground font-medium">Nederland 🇳🇱</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Terminal decoration */}
            <div className="bg-background rounded-lg border border-border overflow-hidden hidden lg:block">
              <div className="flex items-center gap-2 px-4 py-3 border-b border-border bg-secondary/50">
                <span className="w-3 h-3 rounded-full bg-destructive/60" />
                <span className="w-3 h-3 rounded-full bg-yellow-500/60" />
                <span className="w-3 h-3 rounded-full bg-green-500/60" />
                <span className="ml-2 text-xs font-mono text-muted-foreground">contact.sh</span>
              </div>
              <div className="p-5 font-mono text-sm space-y-1.5">
                <p><span className="text-primary">$</span> <span className="text-muted-foreground">echo "Heb je een vraag?"</span></p>
                <p className="text-green-400">{lang === "nl" ? "Stuur mij een bericht!" : "Send me a message!"}</p>
                <p className="mt-2"><span className="text-primary">$</span> <span className="text-muted-foreground">response_time</span></p>
                <p className="text-foreground">{lang === "nl" ? "Binnen 24 uur" : "Within 24 hours"}</p>
                <p className="flex items-center gap-0.5 mt-2">
                  <span className="text-primary">$</span>{" "}
                  <span className="animate-blink text-foreground ml-1">▋</span>
                </p>
              </div>
            </div>
          </div>

          {/* Right: form */}
          <div>
            {submitted ? (
              <div className="card-glass rounded-xl p-10 flex flex-col items-center justify-center text-center min-h-[400px] gap-4">
                <div className="w-16 h-16 rounded-full bg-green-500/10 border border-green-500/20 flex items-center justify-center">
                  <CheckCircle className="w-8 h-8 text-green-400" />
                </div>
                <h3 className="text-xl font-bold">{t("contact.success.title")}</h3>
                <p className="text-muted-foreground">{t("contact.success.desc")}</p>
                <button
                  onClick={() => setSubmitted(false)}
                  className="mt-4 px-6 py-2 rounded-lg border border-primary/30 text-primary hover:bg-primary/10 transition-colors font-mono text-sm"
                >
                  {lang === "nl" ? "Nog een bericht sturen" : "Send another message"}
                </button>
              </div>
            ) : (
              <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
                <div className="grid sm:grid-cols-2 gap-5">
                  <div>
                    <label className="block text-sm font-medium text-foreground mb-2">{t("contact.form.name")} *</label>
                    <input
                      {...register("name")}
                      placeholder={lang === "nl" ? "Jouw naam" : "Your name"}
                      className="w-full bg-background border border-input rounded-lg px-4 py-3 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/40 focus:border-primary transition-colors"
                    />
                    {errors.name && (
                      <p className="text-destructive text-xs mt-1">{getError(errors.name.message)}</p>
                    )}
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-foreground mb-2">{t("contact.form.email")} *</label>
                    <input
                      {...register("email")}
                      type="email"
                      placeholder={lang === "nl" ? "jouw@email.nl" : "your@email.com"}
                      className="w-full bg-background border border-input rounded-lg px-4 py-3 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/40 focus:border-primary transition-colors"
                    />
                    {errors.email && (
                      <p className="text-destructive text-xs mt-1">{getError(errors.email.message)}</p>
                    )}
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">{t("contact.form.subject")} *</label>
                  <input
                    {...register("subject")}
                    placeholder={lang === "nl" ? "Waar gaat je bericht over?" : "What is your message about?"}
                    className="w-full bg-background border border-input rounded-lg px-4 py-3 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/40 focus:border-primary transition-colors"
                  />
                  {errors.subject && (
                    <p className="text-destructive text-xs mt-1">{getError(errors.subject.message)}</p>
                  )}
                </div>

                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">{t("contact.form.message")} *</label>
                  <textarea
                    {...register("message")}
                    rows={6}
                    placeholder={lang === "nl" ? "Typ hier je bericht..." : "Type your message here..."}
                    className="w-full bg-background border border-input rounded-lg px-4 py-3 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/40 focus:border-primary transition-colors resize-none"
                  />
                  {errors.message && (
                    <p className="text-destructive text-xs mt-1">{getError(errors.message.message)}</p>
                  )}
                </div>

                {serverError && (
                  <p className="text-destructive text-sm bg-destructive/10 border border-destructive/20 rounded-lg px-4 py-3">{serverError}</p>
                )}

                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="w-full py-3 px-6 bg-primary text-primary-foreground rounded-lg font-semibold flex items-center justify-center gap-2 hover:bg-primary/90 transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
                >
                  {isSubmitting ? (
                    <>
                      <span className="w-4 h-4 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin" />
                      {lang === "nl" ? "Verzenden..." : "Sending..."}
                    </>
                  ) : (
                    <>
                      <Send className="w-4 h-4" />
                      {t("contact.form.send")}
                    </>
                  )}
                </button>
              </form>
            )}
          </div>
        </div>
      </div>
    </section>
  );
};
