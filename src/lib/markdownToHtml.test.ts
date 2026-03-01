import { describe, it, expect } from "vitest";
import { markdownToHtml, isHtmlContent } from "./markdownToHtml";

describe("markdownToHtml", () => {
  it("converts headings correctly", () => {
    expect(markdownToHtml("# Heading 1")).toBe("<h1>Heading 1</h1>");
    expect(markdownToHtml("## Heading 2")).toBe("<h2>Heading 2</h2>");
    expect(markdownToHtml("### Heading 3")).toBe("<h3>Heading 3</h3>");
  });

  it("handles paragraphs and empty lines correctly", () => {
    const md = "Paragraph line 1\nParagraph line 2\n\nNew paragraph";
    expect(markdownToHtml(md)).toBe("<p>Paragraph line 1 Paragraph line 2</p><p>New paragraph</p>");
  });

  it("applies inline formatting", () => {
    const md = "This is **bold** and *italic* and `inline code`";
    expect(markdownToHtml(md)).toBe("<p>This is <strong>bold</strong> and <em>italic</em> and <code>inline code</code></p>");
  });

  it("handles standalone images", () => {
    const md = "![alt text](https://example.com/image.png)";
    expect(markdownToHtml(md)).toBe('<img src="https://example.com/image.png" alt="alt text" />');
  });

  it("handles inline images and links", () => {
    const md = "A paragraph with an ![img alt](image.jpg) and a [link](https://example.com).";
    expect(markdownToHtml(md)).toBe('<p>A paragraph with an <img src="image.jpg" alt="img alt" /> and a <a href="https://example.com" target="_blank" rel="noopener noreferrer">link</a>.</p>');
  });

  it("handles unordered lists", () => {
    const md = "- Item 1\n- Item 2\n- Item 3";
    expect(markdownToHtml(md)).toBe("<ul><li>Item 1</li><li>Item 2</li><li>Item 3</li></ul>");
  });

  it("handles horizontal rules", () => {
    const md = "Before HR\n\n---\n\nAfter HR";
    expect(markdownToHtml(md)).toBe("<p>Before HR</p><hr><p>After HR</p>");
  });

  it("handles code blocks with HTML escaping and language tags", () => {
    const md = "```typescript\nconst a = 1 < 2 && 3 > 2;\n```";
    expect(markdownToHtml(md)).toBe('<pre><code class="language-typescript">const a = 1 &lt; 2 &amp;&amp; 3 &gt; 2;</code></pre>');
  });

  it("handles code blocks without language tags", () => {
    const md = "```\njust some code\n```";
    expect(markdownToHtml(md)).toBe("<pre><code>just some code</code></pre>");
  });

  it("integrates mixed content successfully", () => {
    const md = `# Title
Some text with **bold**.

- List 1
- List 2

\`\`\`
code
\`\`\`
`;
    expect(markdownToHtml(md)).toBe("<h1>Title</h1><p>Some text with <strong>bold</strong>.</p><ul><li>List 1</li><li>List 2</li></ul><pre><code>code</code></pre>");
  });
});

describe("isHtmlContent", () => {
  it("returns true for content starting with a tag", () => {
    expect(isHtmlContent("<p>Hello</p>")).toBe(true);
    expect(isHtmlContent("   <div>Spaces before</div>")).toBe(true);
  });

  it("returns false for regular markdown", () => {
    expect(isHtmlContent("# Markdown Title")).toBe(false);
    expect(isHtmlContent("Just some text")).toBe(false);
  });
});
