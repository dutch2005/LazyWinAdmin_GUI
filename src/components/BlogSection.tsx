import { useState, useEffect, useMemo } from "react";
import { useLanguage } from "@/contexts/LanguageContext";
import { db as supabase } from "@/lib/supabaseClient";
import { Link } from "react-router-dom";
import { Calendar, Clock, ArrowRight, Search } from "lucide-react";

type BlogPost = {
  id: string;
  slug: string;
  category: string;
  date: string;
  read_time: number;
  featured: boolean;
  title_nl: string;
  title_en: string;
  excerpt_nl: string;
  excerpt_en: string;
  published: boolean;
};

const categoryColors: Record<string, string> = {
  ai: "text-primary border-primary/30 bg-primary/10",
  news: "text-blue-400 border-blue-400/30 bg-blue-400/10",
  tutorials: "text-green-400 border-green-400/30 bg-green-400/10",
  tools: "text-orange-400 border-orange-400/30 bg-orange-400/10",
};

const categoryLabels: Record<string, { nl: string; en: string }> = {
  ai: { nl: "AI & Automatisering", en: "AI & Automation" },
  news: { nl: "Tech Nieuws", en: "Tech News" },
  tutorials: { nl: "Tutorial", en: "Tutorial" },
  tools: { nl: "Tools", en: "Tools" },
};

const categoryBars: Record<string, string> = {
  ai: "bg-gradient-to-r from-primary to-cyan-400",
  news: "bg-gradient-to-r from-blue-500 to-blue-400",
  tutorials: "bg-gradient-to-r from-green-500 to-green-400",
  tools: "bg-gradient-to-r from-orange-500 to-orange-400",
};

export const BlogSection = () => {
  const { lang, t } = useLanguage();
  const [activeCategory, setActiveCategory] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [posts, setPosts] = useState<BlogPost[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchPosts = async () => {
      setLoading(true);
      const { data } = await supabase
        .from("blog_posts")
        .select("id, slug, category, date, read_time, featured, title_nl, title_en, excerpt_nl, excerpt_en, published")
        .eq("published", true)
        .order("date", { ascending: false });
      setPosts(data || []);
      setLoading(false);
    };
    fetchPosts();
  }, []);

  const categories = [
    { key: "all", label: t("cat.all") },
    { key: "ai", label: t("cat.ai") },
    { key: "news", label: t("cat.news") },
    { key: "tutorials", label: t("cat.tutorials") },
    { key: "tools", label: t("cat.tools") },
  ];

  const filtered = useMemo(() => {
    let result = activeCategory === "all"
      ? posts
      : posts.filter((p) => p.category === activeCategory);

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      result = result.filter((p) => {
        const t = lang === "nl" ? p.title_nl : p.title_en;
        const e = lang === "nl" ? p.excerpt_nl : p.excerpt_en;
        return t.toLowerCase().includes(q) || e.toLowerCase().includes(q);
      });
    }

    return result;
  }, [posts, activeCategory, searchQuery, lang]);

  const featured = filtered.find((p) => p.featured);
  const rest = filtered.filter((p) => !p.featured || activeCategory !== "all");

  const formatDate = (dateStr: string) =>
    new Date(dateStr).toLocaleDateString(lang === "nl" ? "nl-NL" : "en-GB", {
      day: "numeric",
      month: "long",
      year: "numeric",
    });

  const title = (p: BlogPost) => lang === "nl" ? p.title_nl : p.title_en;
  const excerpt = (p: BlogPost) => lang === "nl" ? p.excerpt_nl : p.excerpt_en;

  const SkeletonCard = () => (
    <div className="card-glass rounded-xl overflow-hidden animate-pulse">
      <div className="h-1 w-full bg-secondary" />
      <div className="p-6 space-y-3">
        <div className="h-4 bg-secondary rounded w-1/4" />
        <div className="h-5 bg-secondary rounded" />
        <div className="h-5 bg-secondary rounded w-4/5" />
        <div className="h-4 bg-secondary rounded w-3/4 mt-2" />
        <div className="h-4 bg-secondary rounded w-1/2" />
      </div>
    </div>
  );

  return (
    <section id="blog" className="py-24 bg-background scroll-mt-16">
      <div className="container mx-auto px-4">
        <div className="mb-12">
          <span className="tag-category text-primary font-mono">// {lang === "nl" ? "artikelen" : "articles"}</span>
          <h2 className="text-4xl font-bold mt-2 section-title">{t("posts.title")}</h2>
        </div>

        {/* Search + Category filters */}
        <div className="flex flex-col sm:flex-row gap-4 mb-10">
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder={lang === "nl" ? "Zoek artikelen..." : "Search articles..."}
              className="w-full h-10 pl-10 pr-4 rounded-full border border-border bg-card text-foreground text-sm font-mono placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:border-primary transition-colors"
            />
          </div>
          <div className="flex flex-wrap gap-2">
            {categories.map((cat) => (
              <button
                key={cat.key}
                onClick={() => setActiveCategory(cat.key)}
                className={`tag-category px-4 py-2 rounded-full border transition-all text-sm ${
                  activeCategory === cat.key
                    ? "bg-primary text-primary-foreground border-primary"
                    : "border-border text-muted-foreground hover:border-primary/40 hover:text-foreground"
                }`}
              >
                {cat.label}
              </button>
            ))}
          </div>
        </div>

        {loading ? (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[...Array(6)].map((_, i) => <SkeletonCard key={i} />)}
          </div>
        ) : (
          <>
            {/* Featured post */}
            {featured && activeCategory === "all" && (
              <div className="mb-10">
                <Link to={`/blog/${featured.slug}`}>
                  <article className="card-glass rounded-xl overflow-hidden group cursor-pointer">
                    <div className="p-8 md:p-10">
                      <div className="flex flex-wrap items-center gap-3 mb-4">
                        <span className={`tag-category px-3 py-1 rounded-full border ${categoryColors[featured.category]}`}>
                          {categoryLabels[featured.category]?.[lang]}
                        </span>
                        <span className="tag-category text-primary border border-primary/20 bg-primary/5 px-3 py-1 rounded-full">
                          ★ {lang === "nl" ? "Uitgelicht" : "Featured"}
                        </span>
                      </div>
                      <h3 className="text-2xl md:text-3xl font-bold mb-4 group-hover:text-primary transition-colors">
                        {title(featured)}
                      </h3>
                      <p className="text-muted-foreground text-lg leading-relaxed mb-6 max-w-2xl">
                        {excerpt(featured)}
                      </p>
                      <div className="flex flex-wrap items-center gap-6 text-sm text-muted-foreground">
                        <span className="flex items-center gap-1.5 font-mono">
                          <Calendar className="w-3.5 h-3.5" />
                          {formatDate(featured.date)}
                        </span>
                        <span className="flex items-center gap-1.5 font-mono">
                          <Clock className="w-3.5 h-3.5" />
                          {featured.read_time} {t("posts.minread")}
                        </span>
                        <span className="ml-auto text-primary font-semibold flex items-center gap-1 group-hover:gap-2 transition-all">
                          {t("posts.readmore")}
                        </span>
                      </div>
                    </div>
                  </article>
                </Link>
              </div>
            )}

            {/* Post grid */}
            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
              {(activeCategory === "all" ? rest : filtered).map((post, i) => (
                <Link key={post.id} to={`/blog/${post.slug}`}>
                  <article
                    className="card-glass rounded-xl overflow-hidden group cursor-pointer animate-fade-in-up h-full flex flex-col"
                    style={{ animationDelay: `${i * 0.08}s`, opacity: 0 }}
                  >
                    <div className={`h-1 w-full ${categoryBars[post.category] || "bg-primary"}`} />
                    <div className="p-6 flex flex-col flex-1">
                      <div className="flex items-center gap-2 mb-3">
                        <span className={`tag-category px-2.5 py-1 rounded-full border text-[10px] ${categoryColors[post.category]}`}>
                          {categoryLabels[post.category]?.[lang]}
                        </span>
                      </div>
                      <h3 className="font-bold text-lg mb-3 leading-tight group-hover:text-primary transition-colors line-clamp-2">
                        {title(post)}
                      </h3>
                      <p className="text-muted-foreground text-sm leading-relaxed mb-5 line-clamp-3 flex-1">
                        {excerpt(post)}
                      </p>
                      <div className="flex items-center justify-between text-xs text-muted-foreground font-mono">
                        <span className="flex items-center gap-1">
                          <Calendar className="w-3 h-3" />
                          {formatDate(post.date)}
                        </span>
                        <span className="flex items-center gap-1">
                          <Clock className="w-3 h-3" />
                          {post.read_time} {t("posts.minread")}
                        </span>
                      </div>
                      <div className="mt-4 pt-4 border-t border-border flex items-center text-primary text-sm font-semibold group-hover:gap-2 gap-1 transition-all">
                        {t("posts.readmore")} <ArrowRight className="w-3.5 h-3.5" />
                      </div>
                    </div>
                  </article>
                </Link>
              ))}
            </div>

            {filtered.length === 0 && (
              <div className="text-center py-16 text-muted-foreground">
                <p>{lang === "nl" ? "Geen artikelen gevonden." : "No articles found."}</p>
              </div>
            )}
          </>
        )}
      </div>
    </section>
  );
};
