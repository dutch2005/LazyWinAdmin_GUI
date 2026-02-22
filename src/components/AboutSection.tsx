import { useLanguage } from "@/contexts/LanguageContext";
import profileImg from "@/assets/profile.jpg";
import {
  Server, Cloud, Bot, Shield, Network, Terminal, Code2, Cpu,
  Mail, Linkedin, MapPin, Award, Briefcase, GraduationCap, Languages, Phone,
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
  { icon: Phone, label: { nl: "VoIP / 3CX", en: "VoIP / 3CX" } },
];

const workHistory = [
  {
    role: { nl: "System Administrator", en: "System Administrator" },
    company: "Mitsubishi Motors Europe B.V. (via Data4.nl)",
    period: "Apr 2022 – heden",
    desc: {
      nl: "Systeembeheer bij Mitsubishi Motors, Maastricht-Airport.",
      en: "System administration at Mitsubishi Motors, Maastricht-Airport.",
    },
  },
  {
    role: { nl: "IT System Administrator", en: "IT System Administrator" },
    company: "Data4.nl",
    period: "Jan 2021 – heden",
    desc: {
      nl: "Beheer van werkplek- en serveromgevingen (fysiek + virtueel), remote support voor klanten.",
      en: "Manage workplace and server environments (physical + virtual), remote support for customers.",
    },
  },
  {
    role: { nl: "System Administrator", en: "System Administrator" },
    company: "Mitsubishi Motors Europe B.V. (via Data4.nl)",
    period: "Okt 2019 – Okt 2021",
    desc: {
      nl: "Gebruikersaccounts, Ivanti Workspace Control & Automation, on-prem servers, MS Teams Calling, Azure projecten.",
      en: "User accounts, Ivanti Workspace Control & Automation, on-prem servers, MS Teams Calling, Azure projects.",
    },
  },
  {
    role: { nl: "Diverse detacheringen", en: "Various assignments" },
    company: "Data4.nl",
    period: "2018 – 2019",
    desc: {
      nl: "Servicedesk bij Gemeente Maastricht, ICT medewerker bij Catharina Ziekenhuis, intaker bij VodafoneZiggo, servicedesk bij VieCuri.",
      en: "Service desk at Gemeente Maastricht, ICT staff at Catharina Hospital, intake/integrator at VodafoneZiggo, service desk at VieCuri.",
    },
  },
  {
    role: { nl: "Enterprise Servicedesk NS / Medewerker Automatisering", en: "Enterprise Service Desk NS / Automation Staff" },
    company: "KPN / Data4.nl",
    period: "Dec 2016 – Jan 2021",
    desc: {
      nl: "Enterprise servicedesk voor NS (via KPN) en automatiseringswerkzaamheden bij Data4.nl.",
      en: "Enterprise service desk for NS (via KPN) and automation work at Data4.nl.",
    },
  },
  {
    role: { nl: "Technisch Helpdeskmedewerker", en: "Technical Helpdesk Agent" },
    company: "Teleperformance Benelux",
    period: "Jan 2015 – Dec 2016",
    desc: {
      nl: "Technische support voor Ziggo (TV, internet, VoIP) en Norton (installatie, virusverwijdering, advies).",
      en: "Technical support for Ziggo (TV, internet, VoIP) and Norton (installation, virus removal, advisory).",
    },
  },
  {
    role: { nl: "Medewerker ICT", en: "ICT Staff" },
    company: "Stichting Jeugdzorg Sint Joseph",
    period: "Jun 2009 – Dec 2014",
    desc: {
      nl: "Helpdesk, printers, Dell switches, XenServer virtualisatie, gebruikersondersteuning.",
      en: "Helpdesk, printers, Dell switches, XenServer virtualization, user support.",
    },
  },
];

const certifications = [
  { label: "3CX Basic Certified Engineer V20", icon: "3CX" },
  { label: "3CX Basic Certified Engineer v18", icon: "3CX" },
  { label: "Vibe Coding", icon: "VC" },
  { label: "Ziggo Technische Training", icon: "ZG" },
  { label: "70-697 Configuring Windows Devices", icon: "MS" },
];

const education = [
  {
    school: "Arcus College",
    degree: { nl: "Niveau 4, ICT Beheerder", en: "Level 4, ICT Administrator" },
    period: "2005 – 2009",
  },
  {
    school: "Zuyd University of Applied Sciences",
    degree: { nl: "HBO, Network Infrastructure Design", en: "Bachelor's, Network Infrastructure Design" },
    period: "2004 – 2005",
  },
  {
    school: "Sintermeerten College",
    degree: { nl: "HAVO, Economie en Maatschappij", en: "HAVO, Economics & Society" },
    period: "1997 – 2004",
  },
];

const languages = [
  { lang: { nl: "Nederlands", en: "Dutch" }, level: { nl: "Moedertaal", en: "Native" } },
  { lang: { nl: "Engels", en: "English" }, level: { nl: "Volledig professioneel", en: "Full Professional" } },
  { lang: { nl: "Duits", en: "German" }, level: { nl: "Beperkt werkend", en: "Limited Working" } },
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
                <p className="text-foreground">15+ jaar IT · 50+ projecten 🚀</p>
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
                { num: "15+", label: { nl: "Jaar ervaring", en: "Years experience" } },
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
            <div className="absolute left-4 top-0 bottom-0 w-px bg-border hidden sm:block" />
            <div className="space-y-8">
              {workHistory.map((job, i) => (
                <div key={i} className="sm:pl-12 relative">
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

        {/* Education */}
        <div className="mb-16">
          <h3 className="text-2xl font-bold mb-8 flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-primary/10 border border-primary/20 flex items-center justify-center">
              <GraduationCap className="w-4 h-4 text-primary" />
            </div>
            {lang === "nl" ? "Opleiding" : "Education"}
          </h3>
          <div className="grid sm:grid-cols-3 gap-4">
            {education.map((edu) => (
              <div key={edu.school} className="card-glass rounded-xl p-5">
                <h4 className="font-semibold text-foreground text-sm">{edu.school}</h4>
                <p className="text-primary font-mono text-xs mt-1">{edu.degree[lang]}</p>
                <p className="text-muted-foreground text-xs mt-2">{edu.period}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Certifications */}
        <div className="mb-16">
          <h3 className="text-2xl font-bold mb-8 flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-primary/10 border border-primary/20 flex items-center justify-center">
              <Award className="w-4 h-4 text-primary" />
            </div>
            {lang === "nl" ? "Certificeringen" : "Certifications"}
          </h3>
          <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
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

        {/* Languages */}
        <div>
          <h3 className="text-2xl font-bold mb-8 flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-primary/10 border border-primary/20 flex items-center justify-center">
              <Languages className="w-4 h-4 text-primary" />
            </div>
            {lang === "nl" ? "Talen" : "Languages"}
          </h3>
          <div className="grid grid-cols-3 gap-4 max-w-md">
            {languages.map((l) => (
              <div key={l.lang.en} className="card-glass rounded-xl p-4 text-center">
                <p className="font-semibold text-foreground text-sm">{l.lang[lang]}</p>
                <p className="text-xs text-muted-foreground mt-1">{l.level[lang]}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
};
