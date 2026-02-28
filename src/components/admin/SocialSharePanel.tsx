import { useEffect, useState } from "react";
import { db as supabase } from "@/lib/supabaseClient";
import { Share2, Copy, Check, Linkedin, Twitter, Facebook, MessageCircle } from "lucide-react";

interface Post {
  id: string;
  slug: string;
  title_nl: string;
  title_en: string;
  excerpt_nl: string;
  published: boolean;
}

const SITE_URL = "https://mikemaze.nl";

export function SocialSharePanel() {
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedPost, setSelectedPost] = useState<Post | null>(null);
  const [copied, setCopied] = useState<string | null>(null);

  useEffect(() => {
    const fetch = async () => {
      const { data } = await supabase
        .from("blog_posts")
        .select("id, slug, title_nl, title_en, excerpt_nl, published")
        .eq("published", true)
        .order("date", { ascending: false });
      setPosts(data || []);
      setLoading(false);
    };
    fetch();
  }, []);

  const copyToClipboard = async (text: string, key: string) => {
    await navigator.clipboard.writeText(text);
    setCopied(key);
    setTimeout(() => setCopied(null), 2000);
  };

  const postUrl = selectedPost ? `${SITE_URL}/blog/${selectedPost.slug}` : "";
  const shareText = selectedPost ? `${selectedPost.title_nl} — ${selectedPost.excerpt_nl}` : "";

  const platforms = selectedPost
    ? [
        {
          name: "LinkedIn",
          icon: Linkedin,
          url: `https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(postUrl)}`,
          color: "text-blue-400",
        },
        {
          name: "X / Twitter",
          icon: Twitter,
          url: `https://twitter.com/intent/tweet?text=${encodeURIComponent(selectedPost.title_nl)}&url=${encodeURIComponent(postUrl)}`,
          color: "text-foreground",
        },
        {
          name: "Facebook",
          icon: Facebook,
          url: `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(postUrl)}`,
          color: "text-blue-500",
        },
        {
          name: "WhatsApp",
          icon: MessageCircle,
          url: `https://wa.me/?text=${encodeURIComponent(shareText + " " + postUrl)}`,
          color: "text-green-400",
        },
      ]
    : [];

  const promoSnippet = selectedPost
    ? `📝 ${selectedPost.title_nl}\n\n${selectedPost.excerpt_nl}\n\n🔗 ${postUrl}`
    : "";

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Social Sharing</h1>
        <p className="text-muted-foreground text-sm mt-1">Deel je artikelen op social media</p>
      </div>

      {loading ? (
        <div className="h-32 bg-card rounded-xl animate-pulse" />
      ) : posts.length === 0 ? (
        <div className="text-center py-24 text-muted-foreground">
          <Share2 className="w-10 h-10 mx-auto mb-3 opacity-40" />
          <p className="text-lg font-medium">Geen gepubliceerde artikelen</p>
          <p className="text-sm mt-1">Publiceer eerst een artikel om te delen.</p>
        </div>
      ) : (
        <div className="space-y-6">
          {/* Post selector */}
          <div className="card-glass rounded-xl p-5">
            <label className="block text-xs font-medium text-muted-foreground mb-2">Kies een artikel</label>
            <select
              value={selectedPost?.id || ""}
              onChange={(e) => setSelectedPost(posts.find((p) => p.id === e.target.value) || null)}
              className="w-full bg-background border border-input rounded-lg px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary/40"
            >
              <option value="">Selecteer een artikel...</option>
              {posts.map((p) => (
                <option key={p.id} value={p.id}>{p.title_nl}</option>
              ))}
            </select>
          </div>

          {selectedPost && (
            <>
              {/* Platform share buttons */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                {platforms.map((platform) => (
                  <div key={platform.name} className="card-glass rounded-xl p-4 flex items-center gap-3">
                    <platform.icon className={`w-5 h-5 ${platform.color} flex-shrink-0`} />
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold">{platform.name}</p>
                    </div>
                    <div className="flex items-center gap-2 flex-shrink-0">
                      <button
                        onClick={() => copyToClipboard(platform.url, platform.name)}
                        className="p-2 rounded-lg border border-border hover:border-primary/40 hover:bg-primary/5 transition-colors"
                        title="Kopieer link"
                      >
                        {copied === platform.name ? <Check className="w-4 h-4 text-green-400" /> : <Copy className="w-4 h-4 text-muted-foreground" />}
                      </button>
                      <a
                        href={platform.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="px-3 py-2 rounded-lg bg-primary/10 text-primary text-xs font-semibold hover:bg-primary/20 transition-colors"
                      >
                        Delen
                      </a>
                    </div>
                  </div>
                ))}
              </div>

              {/* Promo snippet */}
              <div className="card-glass rounded-xl p-5">
                <div className="flex items-center justify-between mb-3">
                  <h3 className="font-semibold text-sm">Promotietekst</h3>
                  <button
                    onClick={() => copyToClipboard(promoSnippet, "promo")}
                    className="flex items-center gap-2 text-xs text-muted-foreground hover:text-primary transition-colors"
                  >
                    {copied === "promo" ? <Check className="w-3 h-3 text-green-400" /> : <Copy className="w-3 h-3" />}
                    Kopieer
                  </button>
                </div>
                <pre className="text-sm text-muted-foreground whitespace-pre-wrap font-mono bg-background/50 rounded-lg p-3 border border-border">
                  {promoSnippet}
                </pre>
              </div>
            </>
          )}
        </div>
      )}
    </div>
  );
}
