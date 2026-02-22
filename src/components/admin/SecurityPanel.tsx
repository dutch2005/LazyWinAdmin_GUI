import { useEffect, useState } from "react";
import { db as supabase } from "@/lib/supabaseClient";
import { Shield, Key, Clock, AlertTriangle, Check } from "lucide-react";

interface AuditEntry {
  id: string;
  action: string;
  details: string | null;
  created_at: string;
}

export function SecurityPanel() {
  const [email, setEmail] = useState("");
  const [lastSignIn, setLastSignIn] = useState("");
  const [auditLog, setAuditLog] = useState<AuditEntry[]>([]);
  const [loading, setLoading] = useState(true);

  // Password change
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [passwordSaving, setPasswordSaving] = useState(false);
  const [passwordMsg, setPasswordMsg] = useState<{ type: "success" | "error"; text: string } | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      if (session?.user) {
        setEmail(session.user.email || "");
        setLastSignIn(session.user.last_sign_in_at || "");
      }

      const { data: logs } = await supabase
        .from("admin_audit_log")
        .select("*")
        .order("created_at", { ascending: false })
        .limit(10);
      setAuditLog(logs || []);
      setLoading(false);
    };
    fetchData();
  }, []);

  const handlePasswordChange = async () => {
    setPasswordMsg(null);
    if (newPassword.length < 8) {
      setPasswordMsg({ type: "error", text: "Wachtwoord moet minstens 8 tekens bevatten." });
      return;
    }
    if (newPassword !== confirmPassword) {
      setPasswordMsg({ type: "error", text: "Wachtwoorden komen niet overeen." });
      return;
    }
    setPasswordSaving(true);
    const { error } = await supabase.auth.updateUser({ password: newPassword });
    setPasswordSaving(false);
    if (error) {
      setPasswordMsg({ type: "error", text: error.message });
    } else {
      setPasswordMsg({ type: "success", text: "Wachtwoord succesvol gewijzigd." });
      setNewPassword("");
      setConfirmPassword("");
      // Log the action
      const { data: { session } } = await supabase.auth.getSession();
      if (session?.user) {
        await supabase.from("admin_audit_log").insert({
          user_id: session.user.id,
          action: "password_change",
          details: "Password changed via admin panel",
        });
      }
    }
  };

  const inputClass = "w-full bg-background border border-input rounded-lg px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/40";

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Beveiliging</h1>
        <p className="text-muted-foreground text-sm mt-1">Sessie-informatie en wachtwoordbeheer</p>
      </div>

      {/* Session info */}
      <div className="card-glass rounded-xl p-5 space-y-3">
        <h3 className="font-semibold text-sm flex items-center gap-2">
          <Shield className="w-4 h-4 text-primary" /> Huidige sessie
        </h3>
        <div className="grid sm:grid-cols-2 gap-4">
          <div>
            <span className="text-xs text-muted-foreground uppercase tracking-wide">E-mail</span>
            <p className="text-sm font-mono mt-1">{email || "—"}</p>
          </div>
          <div>
            <span className="text-xs text-muted-foreground uppercase tracking-wide">Laatste login</span>
            <p className="text-sm font-mono mt-1">
              {lastSignIn ? new Date(lastSignIn).toLocaleString("nl-NL") : "—"}
            </p>
          </div>
        </div>
      </div>

      {/* Password change */}
      <div className="card-glass rounded-xl p-5 space-y-4">
        <h3 className="font-semibold text-sm flex items-center gap-2">
          <Key className="w-4 h-4 text-primary" /> Wachtwoord wijzigen
        </h3>
        <div className="space-y-3 max-w-md">
          <div>
            <label className="block text-xs font-medium text-muted-foreground mb-1">Nieuw wachtwoord</label>
            <input
              type="password"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              placeholder="Minstens 8 tekens"
              className={inputClass}
            />
          </div>
          <div>
            <label className="block text-xs font-medium text-muted-foreground mb-1">Bevestig wachtwoord</label>
            <input
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="Herhaal wachtwoord"
              className={inputClass}
            />
          </div>
          {passwordMsg && (
            <div className={`flex items-center gap-2 text-sm ${passwordMsg.type === "error" ? "text-destructive" : "text-green-400"}`}>
              {passwordMsg.type === "error" ? <AlertTriangle className="w-4 h-4" /> : <Check className="w-4 h-4" />}
              {passwordMsg.text}
            </div>
          )}
          <button
            onClick={handlePasswordChange}
            disabled={passwordSaving}
            className="px-4 py-2 rounded-lg bg-primary text-primary-foreground text-sm font-semibold hover:bg-primary/90 transition-colors disabled:opacity-60"
          >
            {passwordSaving ? "Opslaan..." : "Wachtwoord wijzigen"}
          </button>
        </div>
      </div>

      {/* Audit log */}
      <div className="card-glass rounded-xl p-5">
        <h3 className="font-semibold text-sm flex items-center gap-2 mb-4">
          <Clock className="w-4 h-4 text-primary" /> Activiteitenlog
        </h3>
        {loading ? (
          <div className="space-y-2">
            {[...Array(3)].map((_, i) => (<div key={i} className="h-10 bg-background/50 rounded-lg animate-pulse" />))}
          </div>
        ) : auditLog.length === 0 ? (
          <p className="text-sm text-muted-foreground">Nog geen activiteiten gelogd.</p>
        ) : (
          <div className="space-y-2">
            {auditLog.map((entry) => (
              <div key={entry.id} className="flex items-center gap-3 py-2 border-b border-border/50 last:border-0">
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium">{entry.action}</p>
                  {entry.details && <p className="text-xs text-muted-foreground truncate">{entry.details}</p>}
                </div>
                <span className="text-xs text-muted-foreground font-mono flex-shrink-0">
                  {new Date(entry.created_at).toLocaleString("nl-NL")}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
