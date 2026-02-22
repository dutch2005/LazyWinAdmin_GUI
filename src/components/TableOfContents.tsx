import { useState, useEffect } from "react";
import { useLanguage } from "@/contexts/LanguageContext";
import { List, ChevronDown, ChevronUp } from "lucide-react";

interface TocItem {
  id: string;
  text: string;
  level: number;
}

interface TableOfContentsProps {
  content: string;
}

function extractHeadings(content: string): TocItem[] {
  const lines = content.split("\n");
  const headings: TocItem[] = [];
  for (const line of lines) {
    const match = line.match(/^(#{2,3})\s+(.+)$/);
    if (match) {
      const level = match[1].length;
      const text = match[2].trim();
      const id = text
        .toLowerCase()
        .replace(/[^a-z0-9\s-]/g, "")
        .replace(/\s+/g, "-");
      headings.push({ id, text, level });
    }
  }
  return headings;
}

export const TableOfContents = ({ content }: TableOfContentsProps) => {
  const { lang } = useLanguage();
  const [activeId, setActiveId] = useState("");
  const [isOpen, setIsOpen] = useState(false);
  const headings = extractHeadings(content);

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            setActiveId(entry.target.id);
          }
        }
      },
      { rootMargin: "-80px 0px -60% 0px" }
    );

    headings.forEach((h) => {
      const el = document.getElementById(h.id);
      if (el) observer.observe(el);
    });

    return () => observer.disconnect();
  }, [headings]);

  if (headings.length < 2) return null;

  const handleClick = (id: string) => {
    const el = document.getElementById(id);
    if (el) {
      el.scrollIntoView({ behavior: "smooth", block: "start" });
      setIsOpen(false);
    }
  };

  return (
    <>
      {/* Desktop: sticky sidebar */}
      <nav className="hidden xl:block sticky top-24 max-h-[calc(100vh-8rem)] overflow-y-auto pr-4">
        <h4 className="text-xs font-mono font-bold uppercase tracking-widest text-muted-foreground mb-4">
          {lang === "nl" ? "Inhoudsopgave" : "Table of Contents"}
        </h4>
        <ul className="space-y-1.5 border-l border-border">
          {headings.map((h) => (
            <li key={h.id}>
              <button
                onClick={() => handleClick(h.id)}
                className={`block w-full text-left text-sm py-1 transition-colors border-l-2 -ml-px ${
                  h.level === 3 ? "pl-6" : "pl-4"
                } ${
                  activeId === h.id
                    ? "border-primary text-primary font-medium"
                    : "border-transparent text-muted-foreground hover:text-foreground hover:border-muted-foreground"
                }`}
              >
                {h.text}
              </button>
            </li>
          ))}
        </ul>
      </nav>

      {/* Mobile: collapsible */}
      <div className="xl:hidden card-glass rounded-xl mb-8">
        <button
          onClick={() => setIsOpen(!isOpen)}
          className="flex items-center justify-between w-full p-4 text-sm font-mono font-bold uppercase tracking-widest text-muted-foreground"
        >
          <span className="flex items-center gap-2">
            <List className="w-4 h-4" />
            {lang === "nl" ? "Inhoudsopgave" : "Table of Contents"}
          </span>
          {isOpen ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
        </button>
        {isOpen && (
          <ul className="px-4 pb-4 space-y-1 border-l border-border ml-4">
            {headings.map((h) => (
              <li key={h.id}>
                <button
                  onClick={() => handleClick(h.id)}
                  className={`block w-full text-left text-sm py-1 transition-colors ${
                    h.level === 3 ? "pl-4" : "pl-2"
                  } ${
                    activeId === h.id
                      ? "text-primary font-medium"
                      : "text-muted-foreground hover:text-foreground"
                  }`}
                >
                  {h.text}
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </>
  );
};

/** Utility: generate id from heading text (used in BlogPost renderer) */
export function headingToId(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, "")
    .replace(/\s+/g, "-");
}
