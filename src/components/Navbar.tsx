import { useState } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { Menu, X } from "lucide-react";
import { useLanguage } from "@/contexts/LanguageContext";

export const Navbar = () => {
  const { lang, setLang, t } = useLanguage();
  const [mobileOpen, setMobileOpen] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();

  const navItems = [
    { key: "nav.home",    section: "home"    },
    { key: "nav.blog",    section: "blog"    },
    { key: "nav.about",   section: "about"   },
    { key: "nav.contact", section: "contact" },
  ];

  const scrollToSection = (section: string) => {
    setMobileOpen(false);

    if (location.pathname === "/") {
      // Already on the homepage — scroll directly
      if (section === "home") {
        window.scrollTo({ top: 0, behavior: "smooth" });
      } else {
        document.getElementById(section)?.scrollIntoView({ behavior: "smooth" });
      }
    } else {
      // On a different page (e.g. /blog/:slug) — navigate home, then scroll
      navigate("/", { state: { scrollTo: section } });
    }
  };

  return (
    <header className="fixed top-0 left-0 right-0 z-50 border-b border-border bg-background/80 backdrop-blur-md">
      <div className="container mx-auto flex h-16 items-center justify-between px-4">
        {/* Logo */}
        <button
          onClick={() => scrollToSection("home")}
          className="flex items-center gap-2 group"
        >
          <div className="flex items-center justify-center w-9 h-9 rounded bg-primary/10 border border-primary/30 group-hover:border-primary/60 transition-colors animate-pulse-cyan">
            <img src="/logo.svg" alt="Mike Maze" className="w-5 h-5" />
          </div>
          <div className="text-left">
            <span className="font-bold text-foreground font-mono text-sm tracking-wide">
              Mike<span className="text-primary">Maze</span>
            </span>
            <div className="text-[10px] text-muted-foreground font-mono leading-none tracking-widest uppercase">
              IT Adventures
            </div>
          </div>
        </button>

        {/* Desktop nav */}
        <nav className="hidden md:flex items-center gap-8">
          {navItems.map((item) => (
            <button
              key={item.key}
              onClick={() => scrollToSection(item.section)}
              className="nav-link-hover text-sm font-medium text-muted-foreground hover:text-foreground transition-colors pb-1"
            >
              {t(item.key)}
            </button>
          ))}
        </nav>

        {/* Language switcher + mobile menu */}
        <div className="flex items-center gap-4">
          {/* Language toggle */}
          <div className="flex items-center bg-secondary rounded-md p-0.5 font-mono text-xs">
            <button
              onClick={() => setLang("nl")}
              className={`px-3 py-1.5 rounded transition-all ${
                lang === "nl"
                  ? "bg-primary text-primary-foreground font-bold"
                  : "text-muted-foreground hover:text-foreground"
              }`}
            >
              NL
            </button>
            <button
              onClick={() => setLang("en")}
              className={`px-3 py-1.5 rounded transition-all ${
                lang === "en"
                  ? "bg-primary text-primary-foreground font-bold"
                  : "text-muted-foreground hover:text-foreground"
              }`}
            >
              EN
            </button>
          </div>

          {/* Mobile hamburger */}
          <button
            className="md:hidden text-muted-foreground hover:text-foreground transition-colors"
            onClick={() => setMobileOpen(!mobileOpen)}
          >
            {mobileOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
          </button>
        </div>
      </div>

      {/* Mobile nav */}
      {mobileOpen && (
        <div className="md:hidden border-t border-border bg-card animate-fade-in">
          <nav className="container mx-auto px-4 py-4 flex flex-col gap-4">
            {navItems.map((item) => (
              <button
                key={item.key}
                onClick={() => scrollToSection(item.section)}
                className="text-left text-sm font-medium text-muted-foreground hover:text-primary transition-colors py-2 border-b border-border/50"
              >
                {t(item.key)}
              </button>
            ))}
          </nav>
        </div>
      )}
    </header>
  );
};
