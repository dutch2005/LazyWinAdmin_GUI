import React, { createContext, useContext, useState } from "react";

type Language = "nl" | "en";

interface LanguageContextType {
  lang: Language;
  setLang: (lang: Language) => void;
  t: (key: string) => string;
}

const translations: Record<Language, Record<string, string>> = {
  nl: {
    // Nav
    "nav.home": "Home",
    "nav.blog": "Blog",
    "nav.about": "Over mij",
    "nav.contact": "Contact",

    // Hero
    "hero.tag": "IT Avonturen",
    "hero.greeting": "Hallo, ik ben",
    "hero.title": "Mike Maze",
    "hero.subtitle": "Tech nieuws · AI Automatisering · IT Avonturen",
    "hero.description":
      "Ontdek de nieuwste ontwikkelingen in technologie, AI en automatisering. Geschreven vanuit een passie voor IT en een oog voor de toekomst.",
    "hero.cta.blog": "Lees de blog",
    "hero.cta.about": "Over mij",

    // Categories
    "cat.all": "Alles",
    "cat.ai": "AI & Automatisering",
    "cat.news": "Tech Nieuws",
    "cat.tutorials": "Tutorials",
    "cat.tools": "Tools & Apps",

    // Posts
    "posts.title": "Laatste Artikelen",
    "posts.readmore": "Lees meer →",
    "posts.minread": "min lezen",

    // About
    "about.tag": "Over mij",
    "about.title": "Michael Maertzdorf",
    "about.alias": "ook bekend als Mike Maze",
    "about.desc1":
      "IT-professional met jarenlange ervaring in systeembeheer, automatisering en het implementeren van slimme technologische oplossingen. Gepassioneerd over AI, cloud-infrastructuur en de nieuwste tech-trends.",
    "about.desc2":
      "Via IT Adventures deel ik mijn kennis, ervaringen en inzichten over de wereld van technologie — voor iedereen die nieuwsgierig is naar de toekomst van IT.",
    "about.skills": "Expertisegebieden",

    // Newsletter
    "newsletter.tag": "Blijf op de hoogte",
    "newsletter.title": "Nieuwsbrief",
    "newsletter.desc": "Ontvang de laatste tech-artikelen direct in je inbox.",
    "newsletter.placeholder": "Jouw e-mailadres",
    "newsletter.btn": "Aanmelden",

    // Footer
    "footer.tagline": "Tech nieuws & IT avonturen",
    "footer.rights": "Alle rechten voorbehouden.",
  },
  en: {
    // Nav
    "nav.home": "Home",
    "nav.blog": "Blog",
    "nav.about": "About",
    "nav.contact": "Contact",

    // Hero
    "hero.tag": "IT Adventures",
    "hero.greeting": "Hi, I'm",
    "hero.title": "Mike Maze",
    "hero.subtitle": "Tech News · AI Automation · IT Adventures",
    "hero.description":
      "Discover the latest developments in technology, AI and automation. Written from a passion for IT and an eye for the future.",
    "hero.cta.blog": "Read the blog",
    "hero.cta.about": "About me",

    // Categories
    "cat.all": "All",
    "cat.ai": "AI & Automation",
    "cat.news": "Tech News",
    "cat.tutorials": "Tutorials",
    "cat.tools": "Tools & Apps",

    // Posts
    "posts.title": "Latest Articles",
    "posts.readmore": "Read more →",
    "posts.minread": "min read",

    // About
    "about.tag": "About me",
    "about.title": "Michael Maertzdorf",
    "about.alias": "also known as Mike Maze",
    "about.desc1":
      "IT professional with years of experience in system administration, automation and implementing smart technological solutions. Passionate about AI, cloud infrastructure and the latest tech trends.",
    "about.desc2":
      "Through IT Adventures, I share my knowledge, experiences and insights about the world of technology — for everyone curious about the future of IT.",
    "about.skills": "Areas of expertise",

    // Newsletter
    "newsletter.tag": "Stay updated",
    "newsletter.title": "Newsletter",
    "newsletter.desc": "Get the latest tech articles directly in your inbox.",
    "newsletter.placeholder": "Your email address",
    "newsletter.btn": "Subscribe",

    // Footer
    "footer.tagline": "Tech news & IT adventures",
    "footer.rights": "All rights reserved.",
  },
};

const LanguageContext = createContext<LanguageContextType | undefined>(undefined);

export const LanguageProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [lang, setLang] = useState<Language>("nl");

  const t = (key: string): string => {
    return translations[lang][key] || key;
  };

  return (
    <LanguageContext.Provider value={{ lang, setLang, t }}>
      {children}
    </LanguageContext.Provider>
  );
};

export const useLanguage = () => {
  const ctx = useContext(LanguageContext);
  if (!ctx) throw new Error("useLanguage must be used within LanguageProvider");
  return ctx;
};
