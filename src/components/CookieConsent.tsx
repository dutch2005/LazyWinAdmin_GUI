import { useState, useEffect } from "react";
import { useLanguage } from "@/contexts/LanguageContext";
import { Cookie, X } from "lucide-react";

const STORAGE_KEY = "mm_consent";


function injectSkimlinks() {
  if (document.getElementById('skimlinks-script')) return;
  const script = document.createElement('script');
  script.id = 'skimlinks-script';
  script.type = 'text/javascript';
  script.src = 'https://s.skimresources.com/js/299018X1786643.skimlinks.js';
  script.async = true;
  document.head.appendChild(script);
}

function updateGtagConsent(granted: boolean) {
  const state = granted ? "granted" : "denied";
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  (window as any).gtag?.("consent", "update", {
    ad_storage: state,
    analytics_storage: state,
    ad_user_data: state,
    ad_personalization: state,
  });
}

export const CookieConsent = () => {
  const { lang } = useLanguage();
  const [visible, setVisible] = useState(false);
  const [showDetails, setShowDetails] = useState(false);

  useEffect(() => {
    if (!localStorage.getItem(STORAGE_KEY)) setVisible(true);
    if (localStorage.getItem(STORAGE_KEY) === "granted") injectSkimlinks();
  }, []);

  const accept = () => {
    localStorage.setItem(STORAGE_KEY, "granted");
    updateGtagConsent(true);
    injectSkimlinks();
    setVisible(false);
  };

  const decline = () => {
    localStorage.setItem(STORAGE_KEY, "declined");
    updateGtagConsent(false);
    setVisible(false);
  };

  if (!visible) return null;

  return (
    <div className="fixed bottom-0 left-0 right-0 z-[9999] animate-fade-in">
      {/* Backdrop blur strip */}
      <div className="bg-card/95 backdrop-blur-md border-t border-border shadow-2xl">
        <div className="container mx-auto max-w-5xl px-4 py-4">
          <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4">

            {/* Icon + text */}
            <div className="flex items-start gap-3 flex-1 min-w-0">
              <div className="flex-shrink-0 mt-0.5 w-8 h-8 rounded bg-primary/10 border border-primary/30 flex items-center justify-center">
                <Cookie className="w-4 h-4 text-primary" />
              </div>
              <div>
                <p className="text-sm font-mono font-bold text-foreground mb-0.5">
                  {lang === "nl" ? "Cookie-instellingen" : "Cookie settings"}
                </p>
                <p className="text-xs text-muted-foreground leading-relaxed">
                  {lang === "nl"
                    ? "We gebruiken cookies voor analyse (Google Analytics) en gepersonaliseerde advertenties (Google Ads). Dit vereist jouw toestemming conform de AVG/GDPR."
                    : "We use cookies for analytics (Google Analytics) and personalised ads (Google Ads). Your consent is required under GDPR."}
                  {" "}
                  <button
                    onClick={() => setShowDetails(!showDetails)}
                    className="text-primary underline hover:text-primary/80 transition-colors font-mono"
                  >
                    {lang === "nl" ? (showDetails ? "Verberg details" : "Meer info") : (showDetails ? "Hide details" : "More info")}
                  </button>
                </p>

                {showDetails && (
                  <div className="mt-2 p-3 rounded-md bg-secondary/40 border border-border text-xs text-muted-foreground space-y-1.5 font-mono">
                    <p>
                      <span className="text-foreground font-semibold">
                        {lang === "nl" ? "Functioneel (altijd aan):" : "Functional (always on):"}
                      </span>{" "}
                      {lang === "nl"
                        ? "Noodzakelijk voor de werking van de website. Geen toestemming vereist."
                        : "Essential for the website to function. No consent required."}
                    </p>
                    <p>
                      <span className="text-primary font-semibold">
                        {lang === "nl" ? "Analytisch & Advertenties:" : "Analytics & Advertising:"}
                      </span>{" "}
                      {lang === "nl"
                        ? "Google Analytics (bezoekersstatistieken) en Google Ads (gepersonaliseerde advertenties). Worden alleen geactiveerd met jouw toestemming."
                        : "Google Analytics (visitor stats) and Google Ads (personalised ads). Only activated with your consent."}
                    </p>
                    <p>
                      <span className="text-primary font-semibold">
                        {lang === "nl" ? "Nieuwsbrief tracking:" : "Newsletter tracking:"}
                      </span>{" "}
                      {lang === "nl"
                        ? "Als je op een link in de nieuwsbrief klikt, onthouden we dit om je toekomstige mails beter af te stemmen. Geen toestemming betekent dat we dit alleen registreren zolang je op de gelinkte pagina bent."
                        : "If you click a newsletter link, we remember this to tailor future emails. No consent means we only register this while you are on the linked page."}
                    </p>
                    <p>
                      {lang === "nl"
                        ? "Je kunt je keuze op elk moment herzien via de cookieverklaring onderaan de pagina."
                        : "You can change your choice at any time via the cookie statement at the bottom of the page."}
                    </p>
                  </div>
                )}
              </div>
            </div>

            {/* Buttons */}
            <div className="flex items-center gap-2 flex-shrink-0 w-full sm:w-auto">
              <button
                onClick={decline}
                className="flex-1 sm:flex-none px-4 py-2 text-xs font-mono font-medium text-muted-foreground border border-border rounded-md hover:border-primary/40 hover:text-foreground transition-colors"
              >
                {lang === "nl" ? "Alleen functioneel" : "Functional only"}
              </button>
              <button
                onClick={accept}
                className="flex-1 sm:flex-none px-4 py-2 text-xs font-mono font-bold bg-primary text-primary-foreground rounded-md hover:bg-primary/90 transition-colors"
              >
                {lang === "nl" ? "Alles accepteren" : "Accept all"}
              </button>
              <button
                onClick={decline}
                aria-label="Sluiten"
                className="p-2 text-muted-foreground hover:text-foreground transition-colors"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
