import heroBg from "@/assets/hero-bg.jpg";
import { useLanguage } from "@/contexts/LanguageContext";
import { ArrowRight, ChevronDown } from "lucide-react";

export const Hero = () => {
  const { t } = useLanguage();

  return (
    <section id="home" className="relative min-h-screen flex items-center overflow-hidden scanlines">
      {/* Background image */}
      <div
        className="absolute inset-0 bg-cover bg-center bg-no-repeat"
        style={{ backgroundImage: `url(${heroBg})` }}
      />
      {/* Dark overlay */}
      <div className="absolute inset-0 bg-background/75" />
      {/* Bottom fade */}
      <div className="absolute bottom-0 left-0 right-0 h-48 bg-gradient-to-t from-background to-transparent" />
      {/* Dot pattern overlay */}
      <div className="absolute inset-0 dot-pattern opacity-40" />

      {/* Content */}
      <div className="relative z-10 container mx-auto px-4 py-32">
        <div className="max-w-3xl">
          {/* Tag */}
          <div
            className="inline-flex items-center gap-2 bg-primary/10 border border-primary/30 rounded-full px-4 py-1.5 mb-8 animate-fade-in-up"
            style={{ animationDelay: "0.1s", opacity: 0 }}
          >
            <span className="w-2 h-2 rounded-full bg-primary animate-pulse" />
            <span className="tag-category text-primary">{t("hero.tag")}</span>
          </div>

          {/* Greeting */}
          <p
            className="text-muted-foreground font-mono text-lg mb-2 animate-fade-in-up"
            style={{ animationDelay: "0.2s", opacity: 0 }}
          >
            <span className="text-primary">$</span> {t("hero.greeting")}
          </p>

          {/* Name */}
          <h1
            className="text-6xl md:text-8xl font-bold mb-4 animate-fade-in-up leading-tight"
            style={{ animationDelay: "0.3s", opacity: 0 }}
          >
            <span className="text-gradient-cyan">Mike Maze</span>
          </h1>

          {/* Subtitle */}
          <p
            className="font-mono text-muted-foreground text-sm tracking-widest uppercase mb-6 animate-fade-in-up"
            style={{ animationDelay: "0.4s", opacity: 0 }}
          >
            {t("hero.subtitle")}
          </p>

          {/* Description */}
          <p
            className="text-lg text-muted-foreground max-w-xl leading-relaxed mb-10 animate-fade-in-up"
            style={{ animationDelay: "0.5s", opacity: 0 }}
          >
            {t("hero.description")}
          </p>

          {/* CTAs */}
          <div
            className="flex flex-wrap gap-4 animate-fade-in-up"
            style={{ animationDelay: "0.6s", opacity: 0 }}
          >
            <a
              href="#blog"
              className="inline-flex items-center gap-2 bg-primary text-primary-foreground px-6 py-3 rounded-md font-semibold hover:opacity-90 transition-all glow-cyan group"
            >
              {t("hero.cta.blog")}
              <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
            </a>
            <a
              href="#about"
              className="inline-flex items-center gap-2 border border-border text-foreground px-6 py-3 rounded-md font-semibold hover:border-primary/50 hover:text-primary transition-all"
            >
              {t("hero.cta.about")}
            </a>
          </div>
        </div>
      </div>

      {/* Scroll indicator */}
      <a
        href="#blog"
        className="absolute bottom-8 left-1/2 -translate-x-1/2 z-10 flex flex-col items-center gap-2 text-muted-foreground hover:text-primary transition-colors"
      >
        <span className="text-xs font-mono tracking-widest uppercase">scroll</span>
        <ChevronDown className="w-5 h-5 animate-bounce" />
      </a>
    </section>
  );
};
