import { Link } from "react-router-dom";
import { useLanguage } from "@/contexts/LanguageContext";
import { Calendar, Clock, ArrowRight } from "lucide-react";

interface PostSummary {
  id: string;
  slug: string;
  category: string;
  date: string;
  read_time: number;
  title_nl: string;
  title_en: string;
  excerpt_nl: string;
  excerpt_en: string;
}

interface RelatedPostsProps {
  currentPostId: string;
  currentCategory: string;
  allPosts: PostSummary[];
}

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

export const RelatedPosts = ({ currentPostId, currentCategory, allPosts }: RelatedPostsProps) => {
  const { lang } = useLanguage();

  const others = allPosts.filter((p) => p.id !== currentPostId);
  const sameCategory = others.filter((p) => p.category === currentCategory);
  const different = others.filter((p) => p.category !== currentCategory);
  const related = [...sameCategory, ...different].slice(0, 3);

  if (related.length === 0) return null;

  const formatDate = (dateStr: string) =>
    new Date(dateStr).toLocaleDateString(lang === "nl" ? "nl-NL" : "en-GB", {
      day: "numeric",
      month: "long",
      year: "numeric",
    });

  return (
    <section className="container mx-auto px-4 max-w-5xl pb-24">
      <div className="border-t border-border pt-12">
        <h3 className="text-2xl font-bold mb-8 section-title">
          {lang === "nl" ? "Gerelateerde artikelen" : "Related Articles"}
        </h3>
        <div className="grid md:grid-cols-3 gap-6">
          {related.map((post) => (
            <Link key={post.id} to={`/blog/${post.slug}`}>
              <article className="card-glass rounded-xl overflow-hidden group cursor-pointer h-full flex flex-col">
                <div className={`h-1 w-full ${categoryBars[post.category] || "bg-primary"}`} />
                <div className="p-5 flex flex-col flex-1">
                  <span
                    className={`tag-category px-2.5 py-1 rounded-full border text-[10px] self-start mb-3 ${categoryColors[post.category]}`}
                  >
                    {categoryLabels[post.category]?.[lang]}
                  </span>
                  <h4 className="font-bold text-base mb-2 leading-tight group-hover:text-primary transition-colors line-clamp-2">
                    {lang === "nl" ? post.title_nl : post.title_en}
                  </h4>
                  <p className="text-muted-foreground text-sm leading-relaxed mb-4 line-clamp-2 flex-1">
                    {lang === "nl" ? post.excerpt_nl : post.excerpt_en}
                  </p>
                  <div className="flex items-center justify-between text-xs text-muted-foreground font-mono">
                    <span className="flex items-center gap-1">
                      <Calendar className="w-3 h-3" />
                      {formatDate(post.date)}
                    </span>
                    <span className="flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      {post.read_time} {lang === "nl" ? "min" : "min"}
                    </span>
                  </div>
                  <div className="mt-3 pt-3 border-t border-border flex items-center text-primary text-sm font-semibold group-hover:gap-2 gap-1 transition-all">
                    {lang === "nl" ? "Lees meer" : "Read more"} <ArrowRight className="w-3.5 h-3.5" />
                  </div>
                </div>
              </article>
            </Link>
          ))}
        </div>
      </div>
    </section>
  );
};
