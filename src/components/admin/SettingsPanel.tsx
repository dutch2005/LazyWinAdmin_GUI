import { Settings, Globe, Info } from "lucide-react";

export function SettingsPanel() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Instellingen</h1>
        <p className="text-muted-foreground text-sm mt-1">Site-configuratie en voorkeuren</p>
      </div>

      {/* Site info */}
      <div className="card-glass rounded-xl p-5 space-y-4">
        <h3 className="font-semibold text-sm flex items-center gap-2">
          <Globe className="w-4 h-4 text-primary" /> Site-informatie
        </h3>
        <div className="grid sm:grid-cols-2 gap-4">
          <div>
            <span className="text-xs text-muted-foreground uppercase tracking-wide">Project</span>
            <p className="text-sm font-mono mt-1">IT Adventures Blog</p>
          </div>
          <div>
            <span className="text-xs text-muted-foreground uppercase tracking-wide">URL</span>
            <p className="text-sm font-mono mt-1">
              <a
                href="https://mikemaze.nl"
                target="_blank"
                rel="noopener noreferrer"
                className="text-primary hover:underline"
              >
                mikemaze.nl
              </a>
            </p>
          </div>
        </div>
      </div>

      {/* Future toggles placeholder */}
      <div className="card-glass rounded-xl p-5 space-y-4">
        <h3 className="font-semibold text-sm flex items-center gap-2">
          <Settings className="w-4 h-4 text-primary" /> Voorkeuren
        </h3>
        <div className="flex items-start gap-3 p-3 rounded-lg bg-background/50 border border-border">
          <Info className="w-4 h-4 text-muted-foreground mt-0.5 flex-shrink-0" />
          <div>
            <p className="text-sm text-muted-foreground">
              Aanvullende instellingen zoals onderhoudsmodus en thema-voorkeuren worden binnenkort toegevoegd.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
