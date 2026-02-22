import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { db as supabase } from "@/lib/supabaseClient";
import { AdminSidebar, type AdminPanel } from "@/components/admin/AdminSidebar";
import { DashboardPanel } from "@/components/admin/DashboardPanel";
import { BlogPostsPanel } from "@/components/admin/BlogPostsPanel";
import { MessagesPanel } from "@/components/admin/MessagesPanel";
import { SubscribersPanel } from "@/components/admin/SubscribersPanel";
import { SocialSharePanel } from "@/components/admin/SocialSharePanel";
import { SecurityPanel } from "@/components/admin/SecurityPanel";
import { SettingsPanel } from "@/components/admin/SettingsPanel";

export default function Admin() {
  const navigate = useNavigate();
  const [activePanel, setActivePanel] = useState<AdminPanel>("dashboard");
  const [collapsed, setCollapsed] = useState(false);
  const [authed, setAuthed] = useState(false);

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

      if (!role) { await supabase.auth.signOut(); navigate("/admin/login"); return; }
      setAuthed(true);

      // Log login
      await supabase.from("admin_audit_log").insert({
        user_id: session.user.id,
        action: "login",
        details: "Admin panel accessed",
      });
    };
    checkAuth();
  }, [navigate]);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    navigate("/admin/login");
  };

  if (!authed) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-primary/30 border-t-primary rounded-full animate-spin" />
      </div>
    );
  }

  const renderPanel = () => {
    switch (activePanel) {
      case "dashboard": return <DashboardPanel onNavigate={setActivePanel} />;
      case "blog": return <BlogPostsPanel />;
      case "messages": return <MessagesPanel />;
      case "subscribers": return <SubscribersPanel />;
      case "social": return <SocialSharePanel />;
      case "security": return <SecurityPanel />;
      case "settings": return <SettingsPanel />;
    }
  };

  return (
    <div className="min-h-screen bg-background flex w-full">
      <AdminSidebar
        active={activePanel}
        onNavigate={setActivePanel}
        onLogout={handleLogout}
        collapsed={collapsed}
        onToggleCollapse={() => setCollapsed(!collapsed)}
      />
      <main className="flex-1 overflow-y-auto">
        <div className="max-w-6xl mx-auto px-6 py-8">
          {renderPanel()}
        </div>
      </main>
    </div>
  );
}
