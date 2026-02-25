import { useEffect, useState, useCallback, useMemo } from "react";
import { useParams, Link, useNavigate } from "react-router-dom";
import { useLanguage } from "@/contexts/LanguageContext";
import { db as supabase } from "@/lib/supabaseClient";
import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { SEOHead } from "@/components/SEOHead";
import { ReadingProgress } from "@/components/ReadingProgress";
import { TableOfContents, headingToId } from "@/components/TableOfContents";
import { RelatedPosts } from "@/components/RelatedPosts";
import { Calendar, Clock, ArrowLeft, ArrowRight, ChevronLeft, Copy, Check } from "lucide-react";
import { isHtmlContent } from "@/lib/markdownToHtml";
import DOMPurify from "dompurify";

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
  news: "text-blue-700 dark:text-blue-400 border-blue-600/30 dark:border-blue-400/30 bg-blue-500/10 dark:bg-blue-400/10",
  tutorials: "text-green-700 dark:text-green-400 border-green-600/30 dark:border-green-400/30 bg-green-500/10 dark:bg-green-400/10",
  tools: "text-orange-700 dark:text-orange-400 border-orange-600/30 dark:border-orange-400/30 bg-orange-500/10 dark:bg-orange-400/10",
};

const categoryLabels: Record<string, { nl: string; en: string }> = {
  ai: { nl: "AI & Automatisering", en: "AI & Automation" },
  news: { nl: "Tech Nieuws", en: "Tech News" },
  tutorials: { nl: "Tutorial", en: "Tutorial" },
  tools: { nl: "Tools", en: "Tools" },
};

function linkify(text: string): string {
  let out = text.replace(
    /\[([^\]]+)\]\((https?:\/\/[^)]+)\)/g,
    '<a href="$2" target="_blank" rel="noopener noreferrer" class="text-primary underline hover:text-primary/80 transition-colors">$1</a>'
  );
  out = out.replace(
    /(?<!href=")(https?:\/\/[^\s<>"]+)/g,
    '<a href="$1" target="_blank" rel="noopener noreferrer" class="text-primary underline hover:text-primary/80 transition-colors">$1</a>'
  );
  out = out.replace(/\*\*(.+?)\*\*/g, '<strong class="text-foreground font-semibold">$1</strong>');
  return out;
}
function CodeBlock({ code, language }: { code: string; language?: string }) {
  const [copied, setCopied] = useState(false);
  const handleCopy = useCallback(() => {
    navigator.clipboard.writeText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }, [code]);

  return (
    <div className="relative group my-6 rounded-lg border border-border overflow-hidden">
      {language && (
        <div className="flex items-center justify-between px-4 py-2 bg-secondary/80 border-b border-border">
          <span className="text-xs font-mono text-muted-foreground uppercase tracking-wider">{language}</span>
          <button
            onClick={handleCopy}
            className="flex items-center gap-1 text-xs font-mono text-muted-foreground hover:text-primary transition-colors"
          >
            {copied ? <Check className="w-3.5 h-3.5" /> : <Copy className="w-3.5 h-3.5" />}
            {copied ? "Copied" : "Copy"}
          </button>
        </div>
      )}
      {!language && (
        <button
          onClick={handleCopy}
          className="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity flex items-center gap-1 text-xs font-mono text-muted-foreground hover:text-primary bg-secondary/80 px-2 py-1 rounded"
        >
          {copied ? <Check className="w-3.5 h-3.5" /> : <Copy className="w-3.5 h-3.5" />}
        </button>
      )}
      <pre className="bg-secondary/30 p-4 overflow-x-auto font-mono text-sm text-foreground leading-relaxed">
        <code>{code}</code>
      </pre>
    </div>
  );
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
        .lte("date", new Date().toISOString().split('T')[0])
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

  // Scroll to top on slug change
  useEffect(() => {
    window.scrollTo({ top: 0 });
  }, [slug]);

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
  const excerpt = lang === "nl" ? post.excerpt_nl : post.excerpt_en;
  const content = lang === "nl" ? post.content_nl : post.content_en;
  const catLabel = categoryLabels[post.category]?.[lang] ?? post.category;

  const isHtml = isHtmlContent(content);
  const paragraphs = isHtml ? [] : content.split("\n\n");

  return (
    <div className="min-h-screen bg-background">
      <SEOHead
        title={title}
        description={excerpt}
        image={post.image_url || undefined}
        url={`/blog/${post.slug}`}
        type="article"
        article={{
          publishedTime: post.date,
          author: "Michael Maertzdorf",
          category: catLabel,
        }}
      />
      <ReadingProgress />
      <Navbar />
      <main>
        {/* Hero */}
        <header className="bg-card border-b border-border py-16">
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
        </header>

        {/* Content with TOC sidebar */}
        <div className="container mx-auto px-4 py-12 max-w-5xl">
          <div className="flex gap-12">
            {/* TOC sidebar (desktop) */}
            <aside className="hidden xl:block w-56 flex-shrink-0">
              <TableOfContents content={content} />
            </aside>

            {/* Main content */}
            <article className="flex-1 max-w-3xl">
              {/* Mobile TOC */}
              <div className="xl:hidden">
                <TableOfContents content={content} />
              </div>

              {isHtml ? (
                <div
                  className="prose-custom prose-headings:text-foreground prose-p:text-muted-foreground prose-p:leading-relaxed prose-a:text-primary prose-a:underline hover:prose-a:text-primary/80 prose-strong:text-foreground prose-li:text-muted-foreground prose-code:text-foreground prose-pre:bg-secondary/30 prose-pre:border prose-pre:border-border prose-img:rounded-lg prose-img:my-6 prose-hr:border-border space-y-1"
                  dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(content) }}
                />
              ) : (
              <div className="prose-custom space-y-1">
                {paragraphs.map((para, i) => {
                  if (para.startsWith("## ")) {
                    const text = para.slice(3);
                    return (
                      <h2 key={i} id={headingToId(text)} className="text-2xl font-bold mt-12 mb-4 text-foreground scroll-mt-20 animate-fade-in" style={{ animationDelay: `${i * 0.02}s` }}>
                        {text}
                      </h2>
                    );
                  }
                  if (para.startsWith("### ")) {
                    const text = para.slice(4);
                    return (
                      <h3 key={i} id={headingToId(text)} className="text-xl font-semibold mt-8 mb-3 text-foreground scroll-mt-20 animate-fade-in" style={{ animationDelay: `${i * 0.02}s` }}>
                        {text}
                      </h3>
                    );
                  }
                  if (para.startsWith("```")) {
                    const langMatch = para.match(/^```(\w+)/);
                    const lang = langMatch?.[1];
                    const codeContent = para.replace(/^```\w*\n?/, "").replace(/```$/, "");
                    return <CodeBlock key={i} code={codeContent} language={lang} />;
                  }
                  if (para.includes("\n- ") || para.startsWith("- ")) {
                    const items = para.split("\n").filter((l) => l.startsWith("- "));
                    return (
                      <ul key={i} className="space-y-2 my-4 ml-2">
                        {items.map((item, j) => (
                          <li key={j} className="flex items-start gap-2 text-muted-foreground leading-relaxed">
                            <span className="text-primary mt-1 flex-shrink-0">•</span>
                            <span dangerouslySetInnerHTML={{ __html: linkify(item.slice(2)) }} />
                          </li>
                        ))}
                      </ul>
                    );
                  }
                  const htmlPara = linkify(para);
                  if (!para.trim()) return null;
                  return (
                    <p key={i} className="text-muted-foreground leading-relaxed my-4" dangerouslySetInnerHTML={{ __html: htmlPara }} />
                  );
                })}
              </div>
              )}
            </article>
          </div>
        </div>

        {/* Prev / Next navigation */}
        <div className="container mx-auto px-4 max-w-3xl pb-12">
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

        {/* Related Posts */}
        <RelatedPosts
          currentPostId={post.id}
          currentCategory={post.category}
          allPosts={allPosts}
        />
      </main>
      <Footer />
    </div>
  );
}
