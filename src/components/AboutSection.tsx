import { useLanguage } from "@/contexts/LanguageContext";
import profileImg from "@/assets/profile.jpg";
import {
  Server, Cloud, Bot, Shield, Network, Terminal, Code2, Cpu,
  Mail, Linkedin, MapPin, Award, Briefcase,
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

const workHistory = [
  {
    role: { nl: "Senior IT Consultant", en: "Senior IT Consultant" },
    company: "Freelance",
    period: "2022 – heden",
    desc: {
      nl: "Advies en implementatie van cloud-infrastructuur, automatisering en AI-oplossingen voor diverse organisaties.",
      en: "Advisory and implementation of cloud infrastructure, automation, and AI solutions for various organizations.",
    },
  },
  {
    role: { nl: "IT Beheerder / Systeembeheerder", en: "IT Administrator / System Administrator" },
    company: "Enterprise klant",
    period: "2018 – 2022",
    desc: {
      nl: "Beheer van Windows Server-omgevingen, Microsoft 365, Azure AD en automatisering via PowerShell en n8n.",
      en: "Management of Windows Server environments, Microsoft 365, Azure AD, and automation via PowerShell and n8n.",
    },
  },
  {
    role: { nl: "Helpdesk / IT Support", en: "Helpdesk / IT Support" },
    company: "IT Services BV",
    period: "2015 – 2018",
    desc: {
      nl: "Eerste en tweede lijn support, hardware troubleshooting, netwerken en gebruikersbeheer.",
      en: "First and second line support, hardware troubleshooting, networking, and user management.",
    },
  },
];

const certifications = [
  { label: "Microsoft 365 Certified", icon: "M365" },
  { label: "3CX V20", icon: "3CX" },
];

export const AboutSection = () => {
  const { lang, t } = useLanguage();

  return (
    <section id="about" className="py-24 bg-card border-t border-border scroll-mt-16">
      <div className="container mx-auto px-4">
        {/* Header */}
        <div className="mb-16">
          <span className="tag-category text-primary font-mono">// {t("about.tag")}</span>
          <h2 className="text-4xl font-bold mt-3">{t("about.title")}</h2>
          <p className="text-muted-foreground font-mono text-sm mt-1">{t("about.alias")}</p>
        </div>

        {/* Top: photo + intro + terminal */}
        <div className="grid lg:grid-cols-2 gap-16 items-start mb-20">
          {/* Left: photo + bio + contact */}
          <div className="space-y-6">
            {/* Photo + name */}
            <div className="flex items-start gap-5">
              <div className="relative flex-shrink-0">
                <div className="w-28 h-28 sm:w-32 sm:h-32 rounded-2xl overflow-hidden border-2 border-primary/30 shadow-lg">
                  <img
                    src={profileImg}
                    alt="Michael Maertzdorf — Mike Maze"
                    className="w-full h-full object-cover"
                  />
                </div>
                <div className="absolute -bottom-1 -right-1 w-5 h-5 rounded-full bg-green-400 border-2 border-card" title="Available" />
              </div>
              <div>
                <h3 className="text-xl font-bold">Michael Maertzdorf</h3>
                <p className="text-primary font-mono text-sm">Mike Maze</p>
                <div className="flex items-center gap-1.5 text-muted-foreground text-sm mt-2">
                  <MapPin className="w-3.5 h-3.5" />
                  <span>Nederland 🇳🇱</span>
                </div>
                <div className="flex items-center gap-3 mt-3">
                  {/* Email obfuscated to prevent scraper harvesting */}
                  <a
                    href="mailto:dutch2005@xtremeweb.xyz"
                    className="flex items-center gap-1.5 text-xs text-muted-foreground hover:text-primary transition-colors font-mono"
                  >
                    <Mail className="w-3.5 h-3.5" />
                    <span style={{ unicodeBidi: "bidi-override", direction: "rtl" }}>
                      zyx.bewemertxe@5002hctud
                    </span>
                  </a>
                </div>
                <div className="flex items-center gap-3 mt-1">
                  <a
                    href="https://www.linkedin.com/in/michael-maertzdorf-b9231420/"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-1.5 text-xs text-muted-foreground hover:text-primary transition-colors font-mono"
                  >
                    <Linkedin className="w-3.5 h-3.5" />
                    LinkedIn
                  </a>
                </div>
              </div>
            </div>

            {/* Bio */}
            <div className="space-y-3 text-muted-foreground leading-relaxed">
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
                <p><span className="text-primary">$</span> <span className="text-muted-foreground">whoami</span></p>
                <p className="text-foreground">
                  Michael Maertzdorf &lt;<span style={{ unicodeBidi: "bidi-override", direction: "rtl" }}>zyx.bewemertxe@5002hctud</span>&gt;
                </p>
                <p className="mt-2"><span className="text-primary">$</span> <span className="text-muted-foreground">cat passion.txt</span></p>
                <p className="text-green-400">AI Automation · Cloud · Security · Tech News</p>
                <p className="mt-2"><span className="text-primary">$</span> <span className="text-muted-foreground">echo $EXPERIENCE</span></p>
                <p className="text-foreground">10+ jaar IT · 50+ projecten 🚀</p>
                <p className="flex items-center gap-0.5 mt-2">
                  <span className="text-primary">$</span>
                  <span className="animate-blink text-foreground ml-1">▋</span>
                </p>
              </div>
            </div>
          </div>

          {/* Right: skills */}
          <div>
            <h3 className="text-lg font-semibold mb-5 flex items-center gap-2">
              <Code2 className="w-4 h-4 text-primary" />
              {t("about.skills")}
            </h3>
            <div className="grid grid-cols-2 gap-3">
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
            <div className="grid grid-cols-3 gap-4 mt-6">
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

        {/* Work history */}
        <div className="mb-16">
          <h3 className="text-2xl font-bold mb-8 flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-primary/10 border border-primary/20 flex items-center justify-center">
              <Briefcase className="w-4 h-4 text-primary" />
            </div>
            {lang === "nl" ? "Werkervaring" : "Work Experience"}
          </h3>
          <div className="relative">
            {/* Timeline line */}
            <div className="absolute left-4 top-0 bottom-0 w-px bg-border hidden sm:block" />
            <div className="space-y-8">
              {workHistory.map((job, i) => (
                <div key={i} className="sm:pl-12 relative">
                  {/* Dot */}
                  <div className="absolute left-2 top-2 w-5 h-5 rounded-full bg-primary/20 border-2 border-primary flex items-center justify-center hidden sm:flex">
                    <div className="w-2 h-2 rounded-full bg-primary" />
                  </div>
                  <div className="card-glass rounded-xl p-5">
                    <div className="flex flex-wrap items-start justify-between gap-2 mb-2">
                      <div>
                        <h4 className="font-semibold text-foreground">{job.role[lang]}</h4>
                        <p className="text-primary font-mono text-sm">{job.company}</p>
                      </div>
                      <span className="text-xs font-mono text-muted-foreground bg-secondary/50 px-2 py-1 rounded-full border border-border whitespace-nowrap">
                        {job.period}
                      </span>
                    </div>
                    <p className="text-muted-foreground text-sm leading-relaxed">{job.desc[lang]}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Certifications */}
        <div>
          <h3 className="text-2xl font-bold mb-8 flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-primary/10 border border-primary/20 flex items-center justify-center">
              <Award className="w-4 h-4 text-primary" />
            </div>
            {lang === "nl" ? "Certificeringen" : "Certifications"}
          </h3>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 max-w-sm">
            {certifications.map((cert) => (
              <div
                key={cert.label}
                className="card-glass rounded-xl p-4 text-center group hover:border-primary/40 transition-colors"
              >
                <div className="w-10 h-10 rounded-lg bg-primary/10 border border-primary/20 flex items-center justify-center mx-auto mb-3 group-hover:bg-primary/20 transition-colors">
                  <span className="text-primary font-mono font-bold text-xs">{cert.icon}</span>
                </div>
                <p className="text-xs text-muted-foreground leading-tight">{cert.label}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
};
