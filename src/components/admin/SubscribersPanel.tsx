import { useEffect, useState } from "react";
import { db as supabase } from "@/lib/supabaseClient";
import { Users, Download } from "lucide-react";

interface Subscriber {
  id: string;
  email: string;
  created_at: string;
}

export function SubscribersPanel() {
  const [subscribers, setSubscribers] = useState<Subscriber[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetch = async () => {
      const { data } = await supabase
        .from("newsletter_subscribers")
        .select("*")
        .order("created_at", { ascending: false });
      setSubscribers(data || []);
      setLoading(false);
    };
    fetch();
  }, []);

  const exportCSV = () => {
    const header = "email,subscribed_at\n";
    const rows = subscribers.map((s) => `${s.email},${s.created_at}`).join("\n");
    const blob = new Blob([header + rows], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `subscribers-${new Date().toISOString().split("T")[0]}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Nieuwsbrief abonnees</h1>
          <p className="text-muted-foreground text-sm mt-1">{subscribers.length} abonnee{subscribers.length !== 1 && "s"}</p>
        </div>
        {subscribers.length > 0 && (
          <button
            onClick={exportCSV}
            className="flex items-center gap-2 px-4 py-2 rounded-lg border border-border text-sm text-muted-foreground hover:text-foreground hover:border-primary/40 transition-colors"
          >
            <Download className="w-4 h-4" />
            Export CSV
          </button>
        )}
      </div>

      {loading ? (
        <div className="space-y-3">
          {[...Array(4)].map((_, i) => (<div key={i} className="h-14 bg-card rounded-xl animate-pulse" />))}
        </div>
      ) : subscribers.length === 0 ? (
        <div className="text-center py-24 text-muted-foreground">
          <Users className="w-10 h-10 mx-auto mb-3 opacity-40" />
          <p className="text-lg font-medium">Nog geen abonnees</p>
        </div>
      ) : (
        <div className="card-glass rounded-xl overflow-hidden">
          <table className="w-full">
            <thead>
              <tr className="border-b border-border">
                <th className="text-left text-xs font-medium text-muted-foreground uppercase tracking-wide px-4 py-3">E-mail</th>
                <th className="text-left text-xs font-medium text-muted-foreground uppercase tracking-wide px-4 py-3">Aangemeld op</th>
              </tr>
            </thead>
            <tbody>
              {subscribers.map((sub) => (
                <tr key={sub.id} className="border-b border-border/50 last:border-0">
                  <td className="px-4 py-3 text-sm font-mono">{sub.email}</td>
                  <td className="px-4 py-3 text-sm text-muted-foreground font-mono">
                    {new Date(sub.created_at).toLocaleDateString("nl-NL")}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
