import {
  LayoutDashboard, FileText, MessageSquare, Users,
  Share2, Shield, Settings, LogOut, ExternalLink
} from "lucide-react";
import { Link } from "react-router-dom";

export type AdminPanel =
  | "dashboard"
  | "blog"
  | "messages"
  | "subscribers"
  | "social"
  | "security"
  | "settings";

const navItems: { id: AdminPanel; label: string; icon: React.ElementType }[] = [
  { id: "dashboard", label: "Dashboard", icon: LayoutDashboard },
  { id: "blog", label: "Blog Posts", icon: FileText },
  { id: "messages", label: "Berichten", icon: MessageSquare },
  { id: "subscribers", label: "Abonnees", icon: Users },
  { id: "social", label: "Social Sharing", icon: Share2 },
  { id: "security", label: "Beveiliging", icon: Shield },
  { id: "settings", label: "Instellingen", icon: Settings },
];

interface AdminSidebarProps {
  active: AdminPanel;
  onNavigate: (panel: AdminPanel) => void;
  onLogout: () => void;
  collapsed: boolean;
  onToggleCollapse: () => void;
}

export function AdminSidebar({ active, onNavigate, onLogout, collapsed, onToggleCollapse }: AdminSidebarProps) {
  return (
    <aside
      className={`sticky top-0 h-screen flex flex-col border-r border-border bg-sidebar transition-all duration-200 ${
        collapsed ? "w-16" : "w-60"
      }`}
    >
      {/* Logo area */}
      <div className="h-16 flex items-center gap-3 px-4 border-b border-border flex-shrink-0">
        <button
          onClick={onToggleCollapse}
          className="w-8 h-8 rounded-lg bg-primary/10 border border-primary/20 flex items-center justify-center hover:bg-primary/20 transition-colors"
        >
          <LayoutDashboard className="w-4 h-4 text-primary" />
        </button>
        {!collapsed && (
          <span className="font-bold text-sidebar-foreground text-sm truncate">
            Admin Panel
          </span>
        )}
      </div>

      {/* Nav items */}
      <nav className="flex-1 py-3 px-2 space-y-1 overflow-y-auto">
        {navItems.map((item) => {
          const isActive = active === item.id;
          return (
            <button
              key={item.id}
              onClick={() => onNavigate(item.id)}
              title={collapsed ? item.label : undefined}
              className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                isActive
                  ? "bg-primary/10 text-primary border border-primary/20"
                  : "text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground border border-transparent"
              }`}
            >
              <item.icon className="w-4 h-4 flex-shrink-0" />
              {!collapsed && <span className="truncate">{item.label}</span>}
            </button>
          );
        })}
      </nav>

      {/* Bottom actions */}
      <div className="px-2 py-3 border-t border-border space-y-1 flex-shrink-0">
        <Link
          to="/"
          target="_blank"
          className="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm text-sidebar-foreground hover:bg-sidebar-accent transition-colors"
        >
          <ExternalLink className="w-4 h-4 flex-shrink-0" />
          {!collapsed && <span>Bekijk site</span>}
        </Link>
        <button
          onClick={onLogout}
          className="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm text-destructive hover:bg-destructive/10 transition-colors"
        >
          <LogOut className="w-4 h-4 flex-shrink-0" />
          {!collapsed && <span>Uitloggen</span>}
        </button>
      </div>
    </aside>
  );
}
