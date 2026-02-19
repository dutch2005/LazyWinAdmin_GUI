
# IT Adventures — All 5 Requests Combined Plan

## What needs to happen

Here's a summary of each of the 5 requests and what will be done:

---

## 1. Make you Admin (Immediate Action)

Your account already exists in the system (`dutch2005@gmail.com`). You have **no admin role assigned yet**, which is why you cannot log into the admin panel.

This will be fixed by inserting your user ID into the `user_roles` table directly via a database operation. No SQL to run manually — it will be done for you as part of this implementation.

After this, you can log into `/admin/login` with your email and password immediately.

---

## 2. Markdown Visual Editor (Rich Text Editor in Admin)

The admin panel currently has plain `<textarea>` fields for article content. This will be replaced with a **custom built-in Markdown toolbar editor** — no external library needed (no new npm packages required).

### How it works:
A `MarkdownEditor` component will be built in `src/components/admin/MarkdownEditor.tsx` that wraps the existing textarea with a toolbar above it. The toolbar will have buttons that insert Markdown syntax at the cursor position.

### Toolbar buttons:
| Button | Action | Inserts |
|---|---|---|
| **B** Bold | Wraps selection | `**text**` |
| *I* Italic | Wraps selection | `*text*` |
| H1 Heading | Line prefix | `## Heading` |
| H2 Sub-heading | Line prefix | `### Subheading` |
| Code Block | Block wrapper | ` ```\ncode\n``` ` |
| Inline Code | Wraps selection | `` `code` `` |
| Bullet List | Line prefix | `- item` |
| Link | Wraps + prompt | `[text](url)` |
| Horizontal Rule | Inserts line | `---` |

### Preview toggle:
A "Preview" tab next to "Write" will render the Markdown to HTML using the same `renderMarkdown()` function already used in `BlogPost.tsx` — so what you see in preview matches exactly what visitors see.

### Files changed:
- **New**: `src/components/admin/MarkdownEditor.tsx`
- **Modified**: `src/pages/Admin.tsx` — replace content textareas with `<MarkdownEditor />`

---

## 3. About Section — Real CV Data + Personal Photo

### Profile photo:
The user will be able to **upload their photo directly via chat**. Until the photo is uploaded, the existing placeholder will remain. The photo should be uploaded as a message attachment and it will replace `src/assets/profile.jpg`.

The `AboutSection.tsx` already has the photo wired in with the correct import. No structural change needed for the photo slot — just the asset file.

### CV data update:
The `AboutSection.tsx` file currently uses placeholder work history and certifications. These will be updated with **real data** matching the CV (Michael Maertzdorf):

**Work history** (to be updated in `AboutSection.tsx`):
- Role, Company, Period, Description — all bilingual NL/EN

**Certifications** (already has good placeholders like M365, AZ-104, CompTIA Security+, etc.):
- These match the CV data already in the file — they will be verified/adjusted

**Contact info:**
- Email: mike@itadventures.nl (already correct)
- LinkedIn: linkedin.com/in/michaelmaertzdorf (already correct)
- Location: Nederland 🇳🇱 (already correct)

**Note**: Since the actual CV document was not provided in this conversation, the work history data in `AboutSection.tsx` already contains realistic placeholder data. To update with **your exact** real work history, please either:
- Share the details in chat (company names, job titles, years, descriptions), or
- Upload your CV as a file/image

---

## 4. End-to-End Site Test

The session replay and current state will be used to verify:

- Blog cards → click → `/blog/:slug` detail page loads
- Prev/Next navigation between posts works
- Contact form submits and saves to database
- Newsletter form submits and saves to database
- NL ↔ EN toggle switches all text
- Mobile layout at 390px (hamburger menu, stacked cards)

Any bugs found will be fixed inline during implementation.

### Currently known issues to fix:
- The `renderMarkdown` function in `BlogPost.tsx` has a regex issue with consecutive list items (`<ul>` wrapping duplicate)
- The `NewsletterSection` has `id="contact"` which conflicts with `ContactSection` also having `id="contact"` — the newsletter section will get `id="newsletter"`

---

## Technical Implementation Order

```text
Step 1 → Insert admin role for dutch2005@gmail.com (user id: 3db93ebb-...)
Step 2 → Build MarkdownEditor component with toolbar + preview
Step 3 → Wire MarkdownEditor into Admin.tsx content fields
Step 4 → Fix newsletter section id conflict (contact → newsletter)
Step 5 → Fix Markdown list rendering bug in BlogPost.tsx
Step 6 → Verify About section CV data is correct / update as needed
Step 7 → Mobile audit — verify responsive layouts across all sections
```

---

## Files Created / Modified

| File | Action |
|---|---|
| Database `user_roles` | Insert admin row for your account |
| `src/components/admin/MarkdownEditor.tsx` | New — toolbar editor with preview |
| `src/pages/Admin.tsx` | Replace textareas with MarkdownEditor |
| `src/components/NewsletterSection.tsx` | Fix `id="contact"` → `id="newsletter"` |
| `src/pages/BlogPost.tsx` | Fix list rendering bug in Markdown parser |
| `src/components/AboutSection.tsx` | Verify/update CV data |

---

## Note on Profile Photo

Your photo can be uploaded at any time by dragging an image into this chat or clicking the paperclip icon. I will use it to replace `src/assets/profile.jpg` immediately when you send it.
