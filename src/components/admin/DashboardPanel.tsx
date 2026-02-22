import { useEffect, useState } from "react";
import { db as supabase } from "@/lib/supabaseClient";
import { FileText, MessageSquare, Users, Eye, EyeOff, Plus, ExternalLink } from "lucide-react";
import type { AdminPanel } from "./AdminSidebar";

interface DashboardPanelProps {
  onNavigate: (panel: AdminPanel) => void;
}

interface Stats {
  totalPosts: number;
  publishedPosts: number;
  draftPosts: number;
  messageCount: number;
  subscriberCount: number;
  recentPosts: { id: string; title_nl: string; date: string; published: boolean; updated_at: string }[];
}

export function DashboardPanel({ onNavigate }: DashboardPanelProps) {
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchStats = async () => {
      const [postsRes, messagesRes, subscribersRes] = await Promise.all([
        supabase.from("blog_posts").select("id, title_nl, date, published, updated_at").order("updated_at", { ascending: false }),
        supabase.from("contact_messages").select("id", { count: "exact", head: true }),
        supabase.from("newsletter_subscribers").select("id", { count: "exact", head: true }),
      ]);

      const posts = postsRes.data || [];
      setStats({
        totalPosts: posts.length,
        publishedPosts: posts.filter((p) => p.published).length,
        draftPosts: posts.filter((p) => !p.published).length,
        messageCount: messagesRes.count || 0,
        subscriberCount: subscribersRes.count || 0,
        recentPosts: posts.slice(0, 5),
      });
      setLoading(false);
    };
    fetchStats();
  }, []);

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="h-24 bg-card rounded-xl animate-pulse" />
          ))}
        </div>
        <div className="h-64 bg-card rounded-xl animate-pulse" />
      </div>
    );
  }

  if (!stats) return null;

  const cards = [
    { label: "Totaal artikelen", value: stats.totalPosts, icon: FileText, color: "text-primary" },
    { label: "Gepubliceerd", value: stats.publishedPosts, icon: Eye, color: "text-green-400" },
    { label: "Concepten", value: stats.draftPosts, icon: EyeOff, color: "text-muted-foreground" },
    { label: "Berichten", value: stats.messageCount, icon: MessageSquare, color: "text-blue-400" },
  ];

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-bold">Dashboard</h1>
        <p className="text-muted-foreground text-sm mt-1">Overzicht van je site</p>
      </div>

      {/* Metric cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {cards.map((card) => (
          <div key={card.label} className="card-glass rounded-xl p-5">
            <div className="flex items-center justify-between">
              <span className="text-xs text-muted-foreground font-medium uppercase tracking-wide">{card.label}</span>
              <card.icon className={`w-4 h-4 ${card.color}`} />
            </div>
            <p className="text-3xl font-bold mt-2 font-mono">{card.value}</p>
          </div>
        ))}
        <div className="card-glass rounded-xl p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs text-muted-foreground font-medium uppercase tracking-wide">Abonnees</span>
            <Users className="w-4 h-4 text-accent" />
          </div>
          <p className="text-3xl font-bold mt-2 font-mono">{stats.subscriberCount}</p>
        </div>
      </div>

      {/* Quick actions */}
      <div className="flex flex-wrap gap-3">
        <button
          onClick={() => onNavigate("blog")}
          className="flex items-center gap-2 px-4 py-2 rounded-lg bg-primary text-primary-foreground text-sm font-semibold hover:bg-primary/90 transition-colors"
        >
          <Plus className="w-4 h-4" />
          Nieuw artikel
        </button>
        <a
          href="/"
          target="_blank"
          rel="noopener noreferrer"
          className="flex items-center gap-2 px-4 py-2 rounded-lg border border-border text-sm text-muted-foreground hover:text-foreground hover:border-primary/40 transition-colors"
        >
          <ExternalLink className="w-4 h-4" />
          Bekijk site
        </a>
      </div>

      {/* Recent posts */}
      <div className="card-glass rounded-xl p-5">
        <h3 className="font-semibold text-sm mb-4">Recente activiteit</h3>
        {stats.recentPosts.length === 0 ? (
          <p className="text-sm text-muted-foreground">Nog geen artikelen.</p>
        ) : (
          <div className="space-y-3">
            {stats.recentPosts.map((post) => (
              <div key={post.id} className="flex items-center justify-between">
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-medium truncate">{post.title_nl}</p>
                  <p className="text-xs text-muted-foreground font-mono">{post.date}</p>
                </div>
                <span className={`text-xs px-2 py-0.5 rounded-full font-mono ${post.published ? "text-green-400 bg-green-400/10" : "text-muted-foreground bg-secondary/50"}`}>
                  {post.published ? "live" : "concept"}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
