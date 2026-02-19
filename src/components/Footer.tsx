import { useLanguage } from "@/contexts/LanguageContext";
import { Terminal, Github, Linkedin, Twitter } from "lucide-react";

export const Footer = () => {
  const { t } = useLanguage();
  const year = new Date().getFullYear();

  return (
    <footer className="bg-card border-t border-border py-12">
      <div className="container mx-auto px-4">
        <div className="flex flex-col md:flex-row items-center justify-between gap-6">
          {/* Logo */}
          <div className="flex items-center gap-3">
            <div className="flex items-center justify-center w-9 h-9 rounded bg-primary/10 border border-primary/30">
              <Terminal className="w-4 h-4 text-primary" />
            </div>
            <div>
              <div className="font-bold font-mono text-sm">
                Mike<span className="text-primary">Maze</span>
              </div>
              <div className="text-[10px] text-muted-foreground font-mono tracking-widest uppercase">
                {t("footer.tagline")}
              </div>
            </div>
          </div>

          {/* Social links */}
          <div className="flex items-center gap-4">
            {[
              { icon: Github, href: "https://github.com", label: "GitHub" },
              { icon: Linkedin, href: "https://linkedin.com", label: "LinkedIn" },
              { icon: Twitter, href: "https://twitter.com", label: "Twitter/X" },
            ].map(({ icon: Icon, href, label }) => (
              <a
                key={label}
                href={href}
                target="_blank"
                rel="noopener noreferrer"
                aria-label={label}
                className="w-9 h-9 flex items-center justify-center rounded-md border border-border text-muted-foreground hover:text-primary hover:border-primary/40 transition-all"
              >
                <Icon className="w-4 h-4" />
              </a>
            ))}
          </div>

          {/* Copyright */}
          <p className="text-xs text-muted-foreground font-mono">
            © {year} Mike Maze — {t("footer.rights")}
          </p>
        </div>
      </div>
    </footer>
  );
};
