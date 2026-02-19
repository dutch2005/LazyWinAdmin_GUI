import { useLanguage } from "@/contexts/LanguageContext";
import {
  Server,
  Cloud,
  Bot,
  Shield,
  Network,
  Terminal,
  Code2,
  Cpu,
} from "lucide-react";

const skills = [
  { icon: Server, label: { nl: "Systeembeheer", en: "System Administration" } },
  { icon: Cloud, label: { nl: "Cloud Infrastructure", en: "Cloud Infrastructure" } },
  { icon: Bot, label: { nl: "AI & Automatisering", en: "AI & Automation" } },
  { icon: Shield, label: { nl: "IT Security", en: "IT Security" } },
  { icon: Network, label: { nl: "Netwerken", en: "Networking" } },
  { icon: Terminal, label: { nl: "PowerShell / Scripting", en: "PowerShell / Scripting" } },
  { icon: Code2, label: { nl: "DevOps", en: "DevOps" } },
  { icon: Cpu, label: { nl: "Hardware & Infra", en: "Hardware & Infra" } },
];

export const AboutSection = () => {
  const { lang, t } = useLanguage();

  return (
    <section id="about" className="py-24 bg-card border-t border-border">
      <div className="container mx-auto px-4">
        <div className="grid lg:grid-cols-2 gap-16 items-center">
          {/* Left: text */}
          <div>
            <span className="tag-category text-primary font-mono">// {t("about.tag")}</span>
            <h2 className="text-4xl font-bold mt-3 mb-1">{t("about.title")}</h2>
            <p className="text-muted-foreground font-mono text-sm mb-8">{t("about.alias")}</p>

            <div className="space-y-4 text-muted-foreground leading-relaxed mb-8">
              <p>{t("about.desc1")}</p>
              <p>{t("about.desc2")}</p>
            </div>

            {/* Terminal card */}
            <div className="bg-background rounded-lg border border-border overflow-hidden">
              <div className="flex items-center gap-2 px-4 py-3 border-b border-border bg-secondary/50">
                <span className="w-3 h-3 rounded-full bg-destructive/60" />
                <span className="w-3 h-3 rounded-full bg-yellow-500/60" />
                <span className="w-3 h-3 rounded-full bg-green-500/60" />
                <span className="ml-2 text-xs font-mono text-muted-foreground">mike@IT-Adventures ~ </span>
              </div>
              <div className="p-5 font-mono text-sm space-y-1.5">
                <p>
                  <span className="text-primary">$</span>{" "}
                  <span className="text-muted-foreground">whoami</span>
                </p>
                <p className="text-foreground">Michael Maertzdorf &lt;mike@itadventures.nl&gt;</p>
                <p className="mt-2">
                  <span className="text-primary">$</span>{" "}
                  <span className="text-muted-foreground">cat passion.txt</span>
                </p>
                <p className="text-green-400">
                  AI Automation · Cloud · Security · Tech News
                </p>
                <p className="mt-2">
                  <span className="text-primary">$</span>{" "}
                  <span className="text-muted-foreground">echo $BLOG</span>
                </p>
                <p className="text-foreground">IT Adventures 🚀</p>
                <p className="flex items-center gap-0.5 mt-2">
                  <span className="text-primary">$</span>{" "}
                  <span className="animate-blink text-foreground ml-1">▋</span>
                </p>
              </div>
            </div>
          </div>

          {/* Right: skills */}
          <div>
            <h3 className="text-xl font-semibold mb-6 text-foreground">{t("about.skills")}</h3>
            <div className="grid grid-cols-2 gap-4">
              {skills.map(({ icon: Icon, label }) => (
                <div
                  key={label.en}
                  className="card-glass rounded-lg p-4 flex items-center gap-3"
                >
                  <div className="flex-shrink-0 w-9 h-9 rounded-md bg-primary/10 border border-primary/20 flex items-center justify-center">
                    <Icon className="w-4 h-4 text-primary" />
                  </div>
                  <span className="text-sm font-medium text-foreground">{label[lang]}</span>
                </div>
              ))}
            </div>

            {/* Stats */}
            <div className="grid grid-cols-3 gap-4 mt-8">
              {[
                { num: "10+", label: { nl: "Jaar ervaring", en: "Years experience" } },
                { num: "50+", label: { nl: "Projecten", en: "Projects" } },
                { num: "∞", label: { nl: "Passie voor IT", en: "Passion for IT" } },
              ].map((stat) => (
                <div key={stat.num} className="text-center p-4 rounded-lg border border-border bg-secondary/30">
                  <div className="text-3xl font-bold text-gradient-cyan">{stat.num}</div>
                  <div className="text-xs text-muted-foreground mt-1">{stat.label[lang]}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
