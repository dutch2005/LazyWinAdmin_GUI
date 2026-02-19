import { useEffect, useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { MarkdownEditor } from "@/components/admin/MarkdownEditor";
import {
  Terminal, LogOut, Plus, Edit, Trash2, Eye, EyeOff,
  Star, StarOff, ChevronLeft, Save, X, AlertTriangle
} from "lucide-react";

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
  content_nl: string;
  content_en: string;
  image_url: string | null;
  published: boolean;
};

type FormData = Omit<BlogPost, "id">;

const emptyForm: FormData = {
  slug: "",
  category: "ai",
  date: new Date().toISOString().split("T")[0],
  read_time: 5,
  featured: false,
  title_nl: "",
  title_en: "",
  excerpt_nl: "",
  excerpt_en: "",
  content_nl: "",
  content_en: "",
  image_url: null,
  published: false,
};

export default function Admin() {
  const navigate = useNavigate();
  const [posts, setPosts] = useState<BlogPost[]>([]);
  const [loading, setLoading] = useState(true);
  const [view, setView] = useState<"list" | "edit" | "new">("list");
  const [editPost, setEditPost] = useState<BlogPost | null>(null);
  const [form, setForm] = useState<FormData>(emptyForm);
  const [saving, setSaving] = useState(false);
  const [deleteId, setDeleteId] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<"nl" | "en">("nl");

  // Auth guard
  useEffect(() => {
    const checkAuth = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) { navigate("/admin/login"); return; }

      const { data: role } = await supabase
        .from("user_roles")
        .select("role")
        .eq("user_id", session.user.id)
        .eq("role", "admin")
        .maybeSingle();

      if (!role) { await supabase.auth.signOut(); navigate("/admin/login"); }
    };
    checkAuth();
  }, [navigate]);

  const fetchPosts = async () => {
    setLoading(true);
    const { data } = await supabase
      .from("blog_posts")
      .select("*")
      .order("date", { ascending: false });
    setPosts(data || []);
    setLoading(false);
  };

  useEffect(() => { fetchPosts(); }, []);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    navigate("/admin/login");
  };

  const openNew = () => {
    setForm(emptyForm);
    setEditPost(null);
    setView("new");
  };

  const openEdit = (post: BlogPost) => {
    setEditPost(post);
    setForm({ ...post });
    setView("edit");
    setActiveTab("nl");
  };

  const handleSave = async () => {
    setSaving(true);
    if (view === "new") {
      await supabase.from("blog_posts").insert({ ...form });
    } else if (editPost) {
      await supabase.from("blog_posts").update({ ...form }).eq("id", editPost.id);
    }
    setSaving(false);
    setView("list");
    fetchPosts();
  };

  const handleDelete = async (id: string) => {
    await supabase.from("blog_posts").delete().eq("id", id);
    setDeleteId(null);
    fetchPosts();
  };

  const togglePublished = async (post: BlogPost) => {
    await supabase.from("blog_posts").update({ published: !post.published }).eq("id", post.id);
    fetchPosts();
  };

  const toggleFeatured = async (post: BlogPost) => {
    await supabase.from("blog_posts").update({ featured: !post.featured }).eq("id", post.id);
    fetchPosts();
  };

  const formField = (label: string, field: keyof FormData, type: "text" | "textarea" | "number" | "date" | "select" | "checkbox" = "text") => {
    const value = form[field];
    const commonClass = "w-full bg-background border border-input rounded-lg px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/40";

    return (
      <div key={field}>
        <label className="block text-xs font-medium text-muted-foreground mb-1">{label}</label>
        {type === "textarea" ? (
          <textarea
            value={value as string}
            onChange={(e) => setForm((f) => ({ ...f, [field]: e.target.value }))}
            rows={6}
            className={commonClass + " resize-y"}
          />
        ) : type === "select" ? (
          <select
            value={value as string}
            onChange={(e) => setForm((f) => ({ ...f, [field]: e.target.value }))}
            className={commonClass}
          >
            {["ai", "news", "tutorials", "tools"].map((c) => (
              <option key={c} value={c}>{c}</option>
            ))}
          </select>
        ) : type === "checkbox" ? (
          <label className="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              checked={value as boolean}
              onChange={(e) => setForm((f) => ({ ...f, [field]: e.target.checked }))}
              className="w-4 h-4 accent-primary"
            />
            <span className="text-sm text-muted-foreground">{label}</span>
          </label>
        ) : (
          <input
            type={type}
            value={value as string | number}
            onChange={(e) => setForm((f) => ({ ...f, [field]: type === "number" ? +e.target.value : e.target.value }))}
            className={commonClass}
          />
        )}
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b border-border bg-card sticky top-0 z-40">
        <div className="container mx-auto px-4 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-primary/10 border border-primary/20 flex items-center justify-center">
              <Terminal className="w-4 h-4 text-primary" />
            </div>
            <span className="font-bold text-foreground">IT Adventures Admin</span>
          </div>
          <div className="flex items-center gap-3">
            <Link to="/" target="_blank" className="text-sm text-muted-foreground hover:text-primary transition-colors font-mono hidden sm:block">
              ↗ Bekijk site
            </Link>
            <button
              onClick={handleLogout}
              className="flex items-center gap-2 text-sm text-muted-foreground hover:text-destructive transition-colors"
            >
              <LogOut className="w-4 h-4" />
              <span className="hidden sm:inline">Uitloggen</span>
            </button>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8">
        {/* === LIST VIEW === */}
        {view === "list" && (
          <div>
            <div className="flex items-center justify-between mb-8">
              <div>
                <h1 className="text-2xl font-bold">Blog Posts</h1>
                <p className="text-muted-foreground text-sm mt-1">{posts.length} {posts.length === 1 ? "artikel" : "artikelen"}</p>
              </div>
              <button
                onClick={openNew}
                className="flex items-center gap-2 bg-primary text-primary-foreground px-4 py-2 rounded-lg text-sm font-semibold hover:bg-primary/90 transition-colors"
              >
                <Plus className="w-4 h-4" />
                Nieuw artikel
              </button>
            </div>

            {loading ? (
              <div className="space-y-3">
                {[...Array(4)].map((_, i) => (
                  <div key={i} className="h-16 bg-card rounded-xl animate-pulse" />
                ))}
              </div>
            ) : posts.length === 0 ? (
              <div className="text-center py-24 text-muted-foreground">
                <p className="text-lg font-medium">Nog geen artikelen</p>
                <p className="text-sm mt-1">Klik op "Nieuw artikel" om te beginnen.</p>
              </div>
            ) : (
              <div className="space-y-3">
                {posts.map((post) => (
                  <div key={post.id} className="card-glass rounded-xl p-4 flex flex-col sm:flex-row sm:items-center gap-4">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className={`text-xs px-2 py-0.5 rounded-full border font-mono ${
                          post.category === "ai" ? "text-primary border-primary/30 bg-primary/10" :
                          post.category === "news" ? "text-blue-400 border-blue-400/30 bg-blue-400/10" :
                          post.category === "tutorials" ? "text-green-400 border-green-400/30 bg-green-400/10" :
                          "text-orange-400 border-orange-400/30 bg-orange-400/10"
                        }`}>{post.category}</span>
                        {post.featured && <span className="text-xs text-yellow-400 font-mono">★ featured</span>}
                        <span className={`text-xs px-2 py-0.5 rounded-full font-mono ${post.published ? "text-green-400 bg-green-400/10" : "text-muted-foreground bg-secondary/50"}`}>
                          {post.published ? "● gepubliceerd" : "○ concept"}
                        </span>
                      </div>
                      <h3 className="font-semibold text-sm mt-1 truncate">{post.title_nl}</h3>
                      <p className="text-xs text-muted-foreground font-mono">{post.date} · {post.read_time} min</p>
                    </div>
                    <div className="flex items-center gap-2 flex-shrink-0">
                      <button
                        onClick={() => toggleFeatured(post)}
                        title={post.featured ? "Verwijder uitlichten" : "Uitlichten"}
                        className="p-2 rounded-lg border border-border hover:border-yellow-400/40 hover:bg-yellow-400/5 transition-colors"
                      >
                        {post.featured ? <Star className="w-4 h-4 text-yellow-400" /> : <StarOff className="w-4 h-4 text-muted-foreground" />}
                      </button>
                      <button
                        onClick={() => togglePublished(post)}
                        title={post.published ? "Verberg" : "Publiceer"}
                        className="p-2 rounded-lg border border-border hover:border-primary/40 hover:bg-primary/5 transition-colors"
                      >
                        {post.published ? <EyeOff className="w-4 h-4 text-muted-foreground" /> : <Eye className="w-4 h-4 text-primary" />}
                      </button>
                      <button
                        onClick={() => openEdit(post)}
                        className="p-2 rounded-lg border border-border hover:border-primary/40 hover:bg-primary/5 transition-colors"
                      >
                        <Edit className="w-4 h-4 text-foreground" />
                      </button>
                      <button
                        onClick={() => setDeleteId(post.id)}
                        className="p-2 rounded-lg border border-border hover:border-destructive/40 hover:bg-destructive/5 transition-colors"
                      >
                        <Trash2 className="w-4 h-4 text-destructive" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* === EDIT / NEW VIEW === */}
        {(view === "edit" || view === "new") && (
          <div>
            <div className="flex items-center gap-4 mb-8">
              <button
                onClick={() => setView("list")}
                className="flex items-center gap-2 text-sm text-muted-foreground hover:text-primary transition-colors"
              >
                <ChevronLeft className="w-4 h-4" />
                Terug
              </button>
              <h1 className="text-2xl font-bold">{view === "new" ? "Nieuw artikel" : "Artikel bewerken"}</h1>
            </div>

            <div className="grid lg:grid-cols-3 gap-8">
              {/* Main content */}
              <div className="lg:col-span-2 space-y-6">
                {/* Language tabs */}
                <div className="flex gap-2 border-b border-border pb-4">
                  {(["nl", "en"] as const).map((l) => (
                    <button
                      key={l}
                      onClick={() => setActiveTab(l)}
                      className={`px-4 py-2 rounded-lg text-sm font-mono transition-colors ${
                        activeTab === l
                          ? "bg-primary text-primary-foreground"
                          : "text-muted-foreground hover:text-foreground border border-border hover:border-primary/40"
                      }`}
                    >
                      {l === "nl" ? "🇳🇱 Nederlands" : "🇬🇧 English"}
                    </button>
                  ))}
                </div>

                {activeTab === "nl" ? (
                  <div className="space-y-4">
                    {formField("Titel (NL)", "title_nl")}
                    {formField("Samenvatting (NL)", "excerpt_nl", "textarea")}
                    <div>
                      <label className="block text-xs font-medium text-muted-foreground mb-1">Inhoud (NL)</label>
                      <MarkdownEditor
                        value={form.content_nl}
                        onChange={(v) => setForm((f) => ({ ...f, content_nl: v }))}
                        placeholder="Schrijf de Nederlandse inhoud in Markdown..."
                        rows={20}
                      />
                    </div>
                  </div>
                ) : (
                  <div className="space-y-4">
                    {formField("Title (EN)", "title_en")}
                    {formField("Excerpt (EN)", "excerpt_en", "textarea")}
                    <div>
                      <label className="block text-xs font-medium text-muted-foreground mb-1">Content (EN)</label>
                      <MarkdownEditor
                        value={form.content_en}
                        onChange={(v) => setForm((f) => ({ ...f, content_en: v }))}
                        placeholder="Write the English content in Markdown..."
                        rows={20}
                      />
                    </div>
                  </div>
                )}
              </div>

              {/* Sidebar */}
              <div className="space-y-6">
                <div className="card-glass rounded-xl p-5 space-y-4">
                  <h3 className="font-semibold text-sm">Instellingen</h3>
                  {formField("Slug (URL)", "slug")}
                  {formField("Categorie", "category", "select")}
                  {formField("Publicatiedatum", "date", "date")}
                  {formField("Leestijd (min)", "read_time", "number")}
                  {formField("Afbeelding URL", "image_url" as keyof FormData)}
                  <div className="space-y-3 pt-2 border-t border-border">
                    {formField("Uitlichten", "featured", "checkbox")}
                    {formField("Gepubliceerd", "published", "checkbox")}
                  </div>
                </div>

                <div className="flex gap-3">
                  <button
                    onClick={() => setView("list")}
                    className="flex-1 py-2 rounded-lg border border-border text-muted-foreground hover:text-foreground text-sm flex items-center justify-center gap-2 transition-colors"
                  >
                    <X className="w-4 h-4" />
                    Annuleren
                  </button>
                  <button
                    onClick={handleSave}
                    disabled={saving}
                    className="flex-1 py-2 rounded-lg bg-primary text-primary-foreground text-sm flex items-center justify-center gap-2 hover:bg-primary/90 transition-colors disabled:opacity-60"
                  >
                    {saving ? (
                      <span className="w-4 h-4 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin" />
                    ) : (
                      <Save className="w-4 h-4" />
                    )}
                    Opslaan
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </main>

      {/* Delete confirm modal */}
      {deleteId && (
        <div className="fixed inset-0 bg-background/80 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-card border border-border rounded-xl p-6 max-w-sm w-full space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-destructive/10 border border-destructive/20 flex items-center justify-center">
                <AlertTriangle className="w-5 h-5 text-destructive" />
              </div>
              <div>
                <h3 className="font-semibold">Artikel verwijderen?</h3>
                <p className="text-sm text-muted-foreground">Dit kan niet ongedaan worden gemaakt.</p>
              </div>
            </div>
            <div className="flex gap-3">
              <button onClick={() => setDeleteId(null)} className="flex-1 py-2 rounded-lg border border-border text-sm">Annuleren</button>
              <button
                onClick={() => handleDelete(deleteId)}
                className="flex-1 py-2 rounded-lg bg-destructive text-destructive-foreground text-sm hover:bg-destructive/90 transition-colors"
              >
                Verwijderen
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
