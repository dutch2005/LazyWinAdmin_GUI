import { useEffect, useState } from "react";
import { db as supabase } from "@/lib/supabaseClient";
import { MessageSquare, ChevronDown, ChevronUp, Mail } from "lucide-react";

interface Message {
  id: string;
  name: string;
  email: string;
  subject: string;
  message: string;
  created_at: string;
}

export function MessagesPanel() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [loading, setLoading] = useState(true);
  const [expandedId, setExpandedId] = useState<string | null>(null);

  useEffect(() => {
    const fetch = async () => {
      const { data } = await supabase
        .from("contact_messages")
        .select("*")
        .order("created_at", { ascending: false });
      setMessages(data || []);
      setLoading(false);
    };
    fetch();
  }, []);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Berichten</h1>
        <p className="text-muted-foreground text-sm mt-1">
          {messages.length} {messages.length === 1 ? "bericht" : "berichten"} ontvangen
        </p>
      </div>

      {loading ? (
        <div className="space-y-3">
          {[...Array(3)].map((_, i) => (
            <div key={i} className="h-20 bg-card rounded-xl animate-pulse" />
          ))}
        </div>
      ) : messages.length === 0 ? (
        <div className="text-center py-24 text-muted-foreground">
          <MessageSquare className="w-10 h-10 mx-auto mb-3 opacity-40" />
          <p className="text-lg font-medium">Nog geen berichten</p>
        </div>
      ) : (
        <div className="space-y-3">
          {messages.map((msg) => {
            const isOpen = expandedId === msg.id;
            return (
              <div key={msg.id} className="card-glass rounded-xl overflow-hidden">
                <button
                  onClick={() => setExpandedId(isOpen ? null : msg.id)}
                  className="w-full p-4 flex items-center gap-4 text-left"
                >
                  <div className="w-9 h-9 rounded-lg bg-blue-400/10 border border-blue-400/20 flex items-center justify-center flex-shrink-0">
                    <Mail className="w-4 h-4 text-blue-400" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="font-semibold text-sm truncate">{msg.name}</span>
                      <span className="text-xs text-muted-foreground font-mono">{msg.email}</span>
                    </div>
                    <p className="text-sm text-muted-foreground truncate">{msg.subject}</p>
                  </div>
                  <div className="flex items-center gap-3 flex-shrink-0">
                    <span className="text-xs text-muted-foreground font-mono hidden sm:block">
                      {new Date(msg.created_at).toLocaleDateString("nl-NL")}
                    </span>
                    {isOpen ? <ChevronUp className="w-4 h-4 text-muted-foreground" /> : <ChevronDown className="w-4 h-4 text-muted-foreground" />}
                  </div>
                </button>
                {isOpen && (
                  <div className="px-4 pb-4 pt-0 border-t border-border">
                    <p className="text-sm text-foreground whitespace-pre-wrap mt-3">{msg.message}</p>
                    <p className="text-xs text-muted-foreground font-mono mt-3">
                      Ontvangen: {new Date(msg.created_at).toLocaleString("nl-NL")}
                    </p>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
