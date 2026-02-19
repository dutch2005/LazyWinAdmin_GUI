import { useRef, useState } from "react";
import {
  Bold, Italic, Heading1, Heading2, Code, List, Link as LinkIcon,
  Minus, Eye, Edit3, FileCode
} from "lucide-react";

interface MarkdownEditorProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  rows?: number;
}

function renderMarkdown(text: string): string {
  let html = text;

  // Code blocks (must be before inline code)
  html = html.replace(
    /```(\w+)?\n([\s\S]*?)```/g,
    '<pre class="bg-secondary/50 border border-border rounded-lg p-4 my-4 overflow-x-auto font-mono text-sm text-foreground"><code>$2</code></pre>'
  );

  // Inline code
  html = html.replace(
    /`([^`]+)`/g,
    '<code class="bg-secondary/50 px-1.5 py-0.5 rounded text-primary font-mono text-sm">$1</code>'
  );

  // Bold
  html = html.replace(/\*\*(.+?)\*\*/g, '<strong class="text-foreground font-semibold">$1</strong>');

  // Italic
  html = html.replace(/\*(.+?)\*/g, '<em class="italic">$1</em>');

  // H2
  html = html.replace(
    /^## (.+)$/gm,
    '<h2 class="text-2xl font-bold mt-10 mb-4 text-foreground">$1</h2>'
  );

  // H3
  html = html.replace(
    /^### (.+)$/gm,
    '<h3 class="text-xl font-semibold mt-8 mb-3 text-foreground">$1</h3>'
  );

  // Horizontal rule
  html = html.replace(/^---$/gm, '<hr class="border-border my-8" />');

  // Links
  html = html.replace(
    /\[([^\]]+)\]\(([^)]+)\)/g,
    '<a href="$2" class="text-primary underline underline-offset-2 hover:opacity-80" target="_blank" rel="noopener noreferrer">$1</a>'
  );

  // Lists — collect consecutive - lines into a single <ul>
  html = html.replace(/((?:^- .+\n?)+)/gm, (match) => {
    const items = match
      .trim()
      .split("\n")
      .filter((l) => l.startsWith("- "))
      .map(
        (l) =>
          `<li class="flex items-start gap-2 text-muted-foreground"><span class="text-primary mt-1">•</span><span>${l.slice(2)}</span></li>`
      )
      .join("");
    return `<ul class="space-y-2 my-4 ml-2">${items}</ul>`;
  });

  // Paragraphs
  html = html
    .split(/\n\n+/)
    .map((block) => {
      const trimmed = block.trim();
      if (!trimmed) return "";
      if (/^<(h[23]|ul|pre|hr)/.test(trimmed)) return trimmed;
      return `<p class="text-muted-foreground leading-relaxed my-4">${trimmed.replace(/\n/g, "<br />")}</p>`;
    })
    .join("\n");

  return html;
}

type ToolbarAction = {
  icon: React.ElementType;
  title: string;
  action: (ta: HTMLTextAreaElement) => void;
};

function wrapSelection(ta: HTMLTextAreaElement, before: string, after: string, placeholder = "text") {
  const start = ta.selectionStart;
  const end = ta.selectionEnd;
  const selected = ta.value.slice(start, end) || placeholder;
  const newVal = ta.value.slice(0, start) + before + selected + after + ta.value.slice(end);
  return { newVal, cursorStart: start + before.length, cursorEnd: start + before.length + selected.length };
}

function prefixLine(ta: HTMLTextAreaElement, prefix: string) {
  const start = ta.selectionStart;
  const lineStart = ta.value.lastIndexOf("\n", start - 1) + 1;
  const newVal = ta.value.slice(0, lineStart) + prefix + ta.value.slice(lineStart);
  return { newVal, cursor: lineStart + prefix.length };
}

function insertAt(ta: HTMLTextAreaElement, text: string) {
  const start = ta.selectionStart;
  const newVal = ta.value.slice(0, start) + text + ta.value.slice(start);
  return { newVal, cursor: start + text.length };
}

export function MarkdownEditor({ value, onChange, placeholder, rows = 18 }: MarkdownEditorProps) {
  const taRef = useRef<HTMLTextAreaElement>(null);
  const [mode, setMode] = useState<"write" | "preview">("write");

  type ApplyResult = { newVal: string; cursor?: number; cursorStart?: number; cursorEnd?: number };

  const apply = (fn: (ta: HTMLTextAreaElement) => ApplyResult | void) => {
    const ta = taRef.current;
    if (!ta) return;
    const result = fn(ta) as ApplyResult | undefined;
    if (!result) return;
    onChange(result.newVal);
    // Restore focus + cursor after React re-render
    requestAnimationFrame(() => {
      ta.focus();
      if (result.cursorStart !== undefined && result.cursorEnd !== undefined) {
        ta.setSelectionRange(result.cursorStart, result.cursorEnd);
      } else if (result.cursor !== undefined) {
        ta.setSelectionRange(result.cursor, result.cursor);
      }
    });
  };

  const tools: ToolbarAction[] = [
    {
      icon: Bold,
      title: "Bold (Ctrl+B)",
      action: (ta) => {
        const r = wrapSelection(ta, "**", "**");
        return r;
      },
    },
    {
      icon: Italic,
      title: "Italic (Ctrl+I)",
      action: (ta) => wrapSelection(ta, "*", "*"),
    },
    {
      icon: Heading1,
      title: "Heading 1 (H2)",
      action: (ta) => {
        const r = prefixLine(ta, "## ");
        return r;
      },
    },
    {
      icon: Heading2,
      title: "Heading 2 (H3)",
      action: (ta) => prefixLine(ta, "### "),
    },
    {
      icon: FileCode,
      title: "Code Block",
      action: (ta) => {
        const start = ta.selectionStart;
        const sel = ta.value.slice(start, ta.selectionEnd) || "code here";
        const block = "```\n" + sel + "\n```";
        const newVal = ta.value.slice(0, start) + block + ta.value.slice(ta.selectionEnd);
        return { newVal, cursor: start + 4 + sel.length + 1 };
      },
    },
    {
      icon: Code,
      title: "Inline Code",
      action: (ta) => wrapSelection(ta, "`", "`", "code"),
    },
    {
      icon: List,
      title: "Bullet List",
      action: (ta) => prefixLine(ta, "- "),
    },
    {
      icon: LinkIcon,
      title: "Link",
      action: (ta) => {
        const url = prompt("URL:");
        if (!url) return { newVal: ta.value };
        return wrapSelection(ta, "[", `](${url})`, "link text");
      },
    },
    {
      icon: Minus,
      title: "Horizontal Rule",
      action: (ta) => {
        const r = insertAt(ta, "\n\n---\n\n");
        return r;
      },
    },
  ];

  return (
    <div className="border border-input rounded-lg overflow-hidden bg-background">
      {/* Toolbar */}
      <div className="flex items-center gap-1 px-2 py-1.5 border-b border-border bg-secondary/30 flex-wrap">
        {/* Write / Preview tabs */}
        <button
          type="button"
          onClick={() => setMode("write")}
          className={`px-3 py-1 text-xs rounded font-mono transition-colors mr-1 ${
            mode === "write"
              ? "bg-primary text-primary-foreground"
              : "text-muted-foreground hover:text-foreground"
          }`}
        >
          <Edit3 className="w-3 h-3 inline mr-1" />
          Write
        </button>
        <button
          type="button"
          onClick={() => setMode("preview")}
          className={`px-3 py-1 text-xs rounded font-mono transition-colors mr-2 ${
            mode === "preview"
              ? "bg-primary text-primary-foreground"
              : "text-muted-foreground hover:text-foreground"
          }`}
        >
          <Eye className="w-3 h-3 inline mr-1" />
          Preview
        </button>

        {/* Divider */}
        <div className="w-px h-5 bg-border mx-1" />

        {/* Format buttons */}
        {tools.map(({ icon: Icon, title, action }) => (
          <button
            key={title}
            type="button"
            title={title}
            onClick={() => apply(action)}
            className="p-1.5 rounded text-muted-foreground hover:text-foreground hover:bg-secondary transition-colors"
          >
            <Icon className="w-3.5 h-3.5" />
          </button>
        ))}
      </div>

      {/* Editor / Preview */}
      {mode === "write" ? (
        <textarea
          ref={taRef}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          rows={rows}
          placeholder={placeholder ?? "Schrijf Markdown hier..."}
          className="w-full bg-transparent px-4 py-3 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none resize-y font-mono leading-relaxed"
        />
      ) : (
        <div
          className="px-4 py-4 min-h-[200px] prose-custom text-sm overflow-auto"
          style={{ minHeight: `${rows * 1.5}rem` }}
          dangerouslySetInnerHTML={{ __html: renderMarkdown(value) || '<p class="text-muted-foreground italic">Nog geen inhoud...</p>' }}
        />
      )}
    </div>
  );
}
