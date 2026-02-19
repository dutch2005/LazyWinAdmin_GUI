import { useEffect, useState } from "react";
import { useParams, Link, useNavigate } from "react-router-dom";
import { useLanguage } from "@/contexts/LanguageContext";
import { db as supabase } from "@/lib/supabaseClient";
import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { Calendar, Clock, ArrowLeft, ArrowRight, ChevronLeft } from "lucide-react";

type BlogPostRow = {
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
  content_nl: string;
  content_en: string;
  image_url: string | null;
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

function renderMarkdown(text: string): string {
  return text
    .replace(/^## (.+)$/gm, '<h2 class="text-2xl font-bold mt-10 mb-4 text-foreground">$1</h2>')
    .replace(/^### (.+)$/gm, '<h3 class="text-xl font-semibold mt-8 mb-3 text-foreground">$1</h3>')
    .replace(/\*\*(.+?)\*\*/g, '<strong class="text-foreground font-semibold">$1</strong>')
    .replace(/```(\w+)?\n([\s\S]*?)```/g, '<pre class="bg-secondary/50 border border-border rounded-lg p-4 my-4 overflow-x-auto font-mono text-sm text-foreground"><code>$2</code></pre>')
    .replace(/`([^`]+)`/g, '<code class="bg-secondary/50 px-1.5 py-0.5 rounded text-primary font-mono text-sm">$1</code>')
    .replace(/^- (.+)$/gm, '<li class="flex items-start gap-2 text-muted-foreground"><span class="text-primary mt-1">•</span><span>$1</span></li>')
    .replace(/(<li[\s\S]*?<\/li>)/g, '<ul class="space-y-2 my-4 ml-2">$1</ul>')
    .replace(/\n\n/g, '</p><p class="text-muted-foreground leading-relaxed my-4">')
    .replace(/^(?!<[hup])/gm, '')
    ;
}

export default function BlogPost() {
  const { slug } = useParams<{ slug: string }>();
  const { lang } = useLanguage();
  const navigate = useNavigate();
  const [post, setPost] = useState<BlogPostRow | null>(null);
  const [allPosts, setAllPosts] = useState<BlogPostRow[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchPosts = async () => {
      setLoading(true);
      const { data } = await supabase
        .from("blog_posts")
        .select("*")
        .eq("published", true)
        .order("date", { ascending: false });

      if (data) {
        setAllPosts(data);
        const found = data.find((p) => p.slug === slug);
        if (!found) navigate("/", { replace: true });
        else setPost(found);
      }
      setLoading(false);
    };
    fetchPosts();
  }, [slug, navigate]);

  const formatDate = (dateStr: string) =>
    new Date(dateStr).toLocaleDateString(lang === "nl" ? "nl-NL" : "en-GB", {
      day: "numeric",
      month: "long",
      year: "numeric",
    });

  const currentIndex = allPosts.findIndex((p) => p.slug === slug);
  const prevPost = currentIndex < allPosts.length - 1 ? allPosts[currentIndex + 1] : null;
  const nextPost = currentIndex > 0 ? allPosts[currentIndex - 1] : null;

  if (loading) {
    return (
      <div className="min-h-screen bg-background">
        <Navbar />
        <main className="container mx-auto px-4 py-24 max-w-3xl">
          <div className="space-y-4 animate-pulse">
            <div className="h-8 bg-secondary rounded w-1/3" />
            <div className="h-12 bg-secondary rounded" />
            <div className="h-4 bg-secondary rounded w-1/4" />
            {[...Array(8)].map((_, i) => (
              <div key={i} className="h-4 bg-secondary rounded" style={{ width: `${80 + Math.random() * 20}%` }} />
            ))}
          </div>
        </main>
        <Footer />
      </div>
    );
  }

  if (!post) return null;

  const title = lang === "nl" ? post.title_nl : post.title_en;
  const content = lang === "nl" ? post.content_nl : post.content_en;
  const catLabel = categoryLabels[post.category]?.[lang] ?? post.category;

  const paragraphs = content.split("\n\n");

  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <main>
        {/* Hero */}
        <div className="bg-card border-b border-border py-16">
          <div className="container mx-auto px-4 max-w-3xl">
            <Link
              to="/#blog"
              className="inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-primary transition-colors mb-8 font-mono"
            >
              <ChevronLeft className="w-4 h-4" />
              {lang === "nl" ? "Terug naar blog" : "Back to blog"}
            </Link>

            <div className="flex flex-wrap items-center gap-3 mb-5">
              <span className={`tag-category px-3 py-1 rounded-full border text-xs ${categoryColors[post.category]}`}>
                {catLabel}
              </span>
              {post.featured && (
                <span className="tag-category text-primary border border-primary/20 bg-primary/5 px-3 py-1 rounded-full text-xs">
                  ★ {lang === "nl" ? "Uitgelicht" : "Featured"}
                </span>
              )}
            </div>

            <h1 className="text-3xl sm:text-4xl md:text-5xl font-bold mb-6 leading-tight">{title}</h1>

            <div className="flex flex-wrap items-center gap-6 text-sm text-muted-foreground font-mono">
              <span className="flex items-center gap-1.5">
                <Calendar className="w-4 h-4" />
                {formatDate(post.date)}
              </span>
              <span className="flex items-center gap-1.5">
                <Clock className="w-4 h-4" />
                {post.read_time} {lang === "nl" ? "min lezen" : "min read"}
              </span>
            </div>
          </div>
        </div>

        {/* Content */}
        <article className="container mx-auto px-4 py-12 max-w-3xl">
          <div className="prose-custom">
            {paragraphs.map((para, i) => {
              if (para.startsWith("## ")) {
                return (
                  <h2 key={i} className="text-2xl font-bold mt-10 mb-4 text-foreground">
                    {para.slice(3)}
                  </h2>
                );
              }
              if (para.startsWith("### ")) {
                return (
                  <h3 key={i} className="text-xl font-semibold mt-8 mb-3 text-foreground">
                    {para.slice(4)}
                  </h3>
                );
              }
              if (para.startsWith("```")) {
                const codeContent = para.replace(/^```\w*\n?/, "").replace(/```$/, "");
                return (
                  <pre key={i} className="bg-secondary/50 border border-border rounded-lg p-4 my-6 overflow-x-auto font-mono text-sm text-foreground">
                    <code>{codeContent}</code>
                  </pre>
                );
              }
              if (para.includes("\n- ") || para.startsWith("- ")) {
                const items = para.split("\n").filter((l) => l.startsWith("- "));
                return (
                  <ul key={i} className="space-y-2 my-4 ml-2">
                    {items.map((item, j) => (
                      <li key={j} className="flex items-start gap-2 text-muted-foreground leading-relaxed">
                        <span className="text-primary mt-1 flex-shrink-0">•</span>
                        <span dangerouslySetInnerHTML={{ __html: item.slice(2).replace(/\*\*(.+?)\*\*/g, '<strong class="text-foreground font-semibold">$1</strong>') }} />
                      </li>
                    ))}
                  </ul>
                );
              }
              // Regular paragraph — handle bold inline
              const htmlPara = para.replace(/\*\*(.+?)\*\*/g, '<strong class="text-foreground font-semibold">$1</strong>');
              if (!para.trim()) return null;
              return (
                <p key={i} className="text-muted-foreground leading-relaxed my-4" dangerouslySetInnerHTML={{ __html: htmlPara }} />
              );
            })}
          </div>
        </article>

        {/* Prev / Next navigation */}
        <div className="container mx-auto px-4 max-w-3xl pb-24">
          <div className="border-t border-border pt-8 grid sm:grid-cols-2 gap-4">
            {prevPost ? (
              <Link
                to={`/blog/${prevPost.slug}`}
                className="card-glass rounded-xl p-5 group hover:border-primary/40 transition-colors"
              >
                <div className="flex items-center gap-2 text-xs text-muted-foreground font-mono mb-2">
                  <ArrowLeft className="w-3.5 h-3.5" />
                  {lang === "nl" ? "Vorig artikel" : "Previous article"}
                </div>
                <p className="font-semibold text-sm leading-snug group-hover:text-primary transition-colors line-clamp-2">
                  {lang === "nl" ? prevPost.title_nl : prevPost.title_en}
                </p>
              </Link>
            ) : <div />}

            {nextPost ? (
              <Link
                to={`/blog/${nextPost.slug}`}
                className="card-glass rounded-xl p-5 group hover:border-primary/40 transition-colors text-right sm:text-right"
              >
                <div className="flex items-center justify-end gap-2 text-xs text-muted-foreground font-mono mb-2">
                  {lang === "nl" ? "Volgend artikel" : "Next article"}
                  <ArrowRight className="w-3.5 h-3.5" />
                </div>
                <p className="font-semibold text-sm leading-snug group-hover:text-primary transition-colors line-clamp-2">
                  {lang === "nl" ? nextPost.title_nl : nextPost.title_en}
                </p>
              </Link>
            ) : <div />}
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}
