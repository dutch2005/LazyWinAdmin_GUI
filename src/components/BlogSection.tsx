import { useState } from "react";
import { useLanguage } from "@/contexts/LanguageContext";
import { blogPosts, BlogPost } from "@/data/blogPosts";
import { Calendar, Clock, ArrowRight } from "lucide-react";

const categoryColors: Record<BlogPost["category"], string> = {
  ai: "text-primary border-primary/30 bg-primary/10",
  news: "text-blue-400 border-blue-400/30 bg-blue-400/10",
  tutorials: "text-green-400 border-green-400/30 bg-green-400/10",
  tools: "text-orange-400 border-orange-400/30 bg-orange-400/10",
};

const categoryLabels: Record<BlogPost["category"], { nl: string; en: string }> = {
  ai: { nl: "AI & Automatisering", en: "AI & Automation" },
  news: { nl: "Tech Nieuws", en: "Tech News" },
  tutorials: { nl: "Tutorial", en: "Tutorial" },
  tools: { nl: "Tools", en: "Tools" },
};

export const BlogSection = () => {
  const { lang, t } = useLanguage();
  const [activeCategory, setActiveCategory] = useState<string>("all");

  const categories = [
    { key: "all", label: t("cat.all") },
    { key: "ai", label: t("cat.ai") },
    { key: "news", label: t("cat.news") },
    { key: "tutorials", label: t("cat.tutorials") },
    { key: "tools", label: t("cat.tools") },
  ];

  const filtered =
    activeCategory === "all"
      ? blogPosts
      : blogPosts.filter((p) => p.category === activeCategory);

  const featured = filtered.find((p) => p.featured);
  const rest = filtered.filter((p) => !p.featured || activeCategory !== "all");

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString(lang === "nl" ? "nl-NL" : "en-GB", {
      day: "numeric",
      month: "long",
      year: "numeric",
    });
  };

  return (
    <section id="blog" className="py-24 bg-background">
      <div className="container mx-auto px-4">
        {/* Header */}
        <div className="mb-12">
          <span className="tag-category text-primary font-mono">// {lang === "nl" ? "artikelen" : "articles"}</span>
          <h2 className="text-4xl font-bold mt-2 section-title">{t("posts.title")}</h2>
        </div>

        {/* Category filter */}
        <div className="flex flex-wrap gap-2 mb-10">
          {categories.map((cat) => (
            <button
              key={cat.key}
              onClick={() => setActiveCategory(cat.key)}
              className={`tag-category px-4 py-2 rounded-full border transition-all ${
                activeCategory === cat.key
                  ? "bg-primary text-primary-foreground border-primary"
                  : "border-border text-muted-foreground hover:border-primary/40 hover:text-foreground"
              }`}
            >
              {cat.label}
            </button>
          ))}
        </div>

        {/* Featured post (only when showing all) */}
        {featured && activeCategory === "all" && (
          <div className="mb-10">
            <article className="card-glass rounded-xl overflow-hidden group cursor-pointer">
              <div className="p-8 md:p-10">
                <div className="flex flex-wrap items-center gap-3 mb-4">
                  <span className={`tag-category px-3 py-1 rounded-full border ${categoryColors[featured.category]}`}>
                    {categoryLabels[featured.category][lang]}
                  </span>
                  <span className="tag-category text-primary border border-primary/20 bg-primary/5 px-3 py-1 rounded-full">
                    ★ {lang === "nl" ? "Uitgelicht" : "Featured"}
                  </span>
                </div>
                <h3 className="text-2xl md:text-3xl font-bold mb-4 group-hover:text-primary transition-colors">
                  {featured.title[lang]}
                </h3>
                <p className="text-muted-foreground text-lg leading-relaxed mb-6 max-w-2xl">
                  {featured.excerpt[lang]}
                </p>
                <div className="flex items-center gap-6 text-sm text-muted-foreground">
                  <span className="flex items-center gap-1.5 font-mono">
                    <Calendar className="w-3.5 h-3.5" />
                    {formatDate(featured.date)}
                  </span>
                  <span className="flex items-center gap-1.5 font-mono">
                    <Clock className="w-3.5 h-3.5" />
                    {featured.readTime} {t("posts.minread")}
                  </span>
                  <span className="ml-auto text-primary font-semibold flex items-center gap-1 group-hover:gap-2 transition-all">
                    {t("posts.readmore")}
                  </span>
                </div>
              </div>
            </article>
          </div>
        )}

        {/* Post grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {(activeCategory === "all" ? rest : filtered).map((post, i) => (
            <article
              key={post.id}
              className="card-glass rounded-xl overflow-hidden group cursor-pointer animate-fade-in-up"
              style={{ animationDelay: `${i * 0.08}s`, opacity: 0 }}
            >
              {/* Top color bar */}
              <div
                className={`h-1 w-full ${
                  post.category === "ai"
                    ? "bg-gradient-to-r from-primary to-cyan-400"
                    : post.category === "news"
                    ? "bg-gradient-to-r from-blue-500 to-blue-400"
                    : post.category === "tutorials"
                    ? "bg-gradient-to-r from-green-500 to-green-400"
                    : "bg-gradient-to-r from-orange-500 to-orange-400"
                }`}
              />
              <div className="p-6">
                <div className="flex items-center gap-2 mb-3">
                  <span className={`tag-category px-2.5 py-1 rounded-full border text-[10px] ${categoryColors[post.category]}`}>
                    {categoryLabels[post.category][lang]}
                  </span>
                </div>
                <h3 className="font-bold text-lg mb-3 leading-tight group-hover:text-primary transition-colors line-clamp-2">
                  {post.title[lang]}
                </h3>
                <p className="text-muted-foreground text-sm leading-relaxed mb-5 line-clamp-3">
                  {post.excerpt[lang]}
                </p>
                <div className="flex items-center justify-between text-xs text-muted-foreground font-mono">
                  <span className="flex items-center gap-1">
                    <Calendar className="w-3 h-3" />
                    {formatDate(post.date)}
                  </span>
                  <span className="flex items-center gap-1">
                    <Clock className="w-3 h-3" />
                    {post.readTime} {t("posts.minread")}
                  </span>
                </div>
                <div className="mt-4 pt-4 border-t border-border flex items-center text-primary text-sm font-semibold group-hover:gap-2 gap-1 transition-all">
                  {t("posts.readmore")} <ArrowRight className="w-3.5 h-3.5" />
                </div>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
};
