# Mike Maze — IT Adventures

Personal tech blog by **Michael Maertzdorf (Mike Maze)** covering IT news, AI automation, PowerShell, cloud infrastructure and system administration.

Live site: [mikemaze.nl](https://mikemaze.nl)

---

## Tech Stack

### Runtime & Build

| Tool | Version | Purpose |
|------|---------|---------|
| **Node.js** | 24 LTS (`>=24.0.0`) | JavaScript runtime |
| **npm** | `>=10.0.0` | Package manager |
| **Vite** | 5.4.x | Dev server & production bundler (SWC transform) |
| **TypeScript** | 5.8.x | Type-safe JavaScript |

### Frontend Framework

| Package | Version | Purpose |
|---------|---------|---------|
| **React** | 19.2.x | UI framework |
| **React DOM** | 19.2.x | DOM renderer |
| **React Router DOM** | 6.30.x | Client-side routing & navigation |
| **React Hook Form** | 7.61.x | Form state management |
| **Zod** | 3.25.x | Schema validation |
| **TanStack Query** | 5.83.x | Server state & async data fetching |

### UI Components & Styling

| Package | Version | Purpose |
|---------|---------|---------|
| **Tailwind CSS** | 3.4.x | Utility-first CSS framework |
| **shadcn/ui** | — | Accessible component system (built on Radix UI) |
| **Radix UI** | various | Headless accessible primitives |
| **Lucide React** | 0.462.x | Icon set |
| **class-variance-authority** | 0.7.x | Component variant management |
| **tailwind-merge** | 2.6.x | Tailwind class merging |
| **tailwindcss-animate** | 1.0.x | Animation utilities |
| **Sonner** | 1.7.x | Toast notifications |
| **Vaul** | 0.9.x | Drawer component |
| **Embla Carousel** | 8.6.x | Touch-friendly carousel |
| **Recharts** | 2.15.x | Chart components |
| **react-day-picker** | 9.13.x | Date picker (v9 API) |
| **cmdk** | 1.1.x | Command palette |

### Backend & Data

| Package | Version | Purpose |
|---------|---------|---------|
| **Supabase JS** | 2.97.x | PostgreSQL database + auth client |

### Analytics & Monetization

| Service | Purpose |
|---------|---------|
| **Google Analytics 4** (`G-0E07DMNCSG`) | Visitor analytics with Consent Mode v2 |
| **Google Consent Mode v2** | GDPR-compliant consent management (EER/EU) |
| **Skimlinks** (`299018X1786643`) | Automatic affiliate link monetization |

### Dev Tools

| Package | Version | Purpose |
|---------|---------|---------|
| **Vitest** | 3.2.x | Unit test runner |
| **@testing-library/react** | 16.0.x | React component testing |
| **ESLint** | 9.32.x | Linting (flat config) |
| **typescript-eslint** | 8.38.x | TypeScript-aware lint rules |
| **@vitejs/plugin-react-swc** | 3.11.x | Fast React transform via SWC |
| **PostCSS** | 8.5.x | CSS processing |
| **Autoprefixer** | 10.4.x | CSS vendor prefixes |

---

## Project Structure

```
mike-maze-it-adventures/
├── public/
│   └── logo.svg              # MM brand logo (favicon + navbar)
├── src/
│   ├── components/
│   │   ├── Navbar.tsx        # Fixed nav with smooth scroll + React Router
│   │   ├── Hero.tsx          # Full-screen landing section
│   │   ├── BlogSection.tsx   # Post grid with category filters
│   │   ├── AboutSection.tsx  # Profile & skills
│   │   ├── ContactSection.tsx
│   │   ├── NewsletterSection.tsx
│   │   ├── Footer.tsx
│   │   ├── CookieConsent.tsx # GDPR banner (NL/EN, Consent Mode v2)
│   │   └── ui/               # shadcn/ui primitives
│   ├── pages/
│   │   ├── Index.tsx         # Homepage (all sections)
│   │   ├── BlogPost.tsx      # Individual post renderer
│   │   ├── Admin.tsx         # Post management
│   │   └── AdminLogin.tsx
│   ├── contexts/
│   │   └── LanguageContext.tsx  # NL/EN i18n
│   ├── lib/
│   │   └── supabaseClient.ts
│   └── main.tsx
├── index.html                # GA4 + Consent Mode v2 + Skimlinks
└── package.json
```

---

## Getting Started

**Requirements:** Node.js 24 LTS, npm 10+

```bash
# Clone
git clone https://github.com/dutch2005/mike-maze-it-adventures.git
cd mike-maze-it-adventures

# Install dependencies
npm install

# Start dev server (http://localhost:5173)
npm run dev

# Production build
npm run build

# Preview production build locally
npm run preview

# Run tests
npm test
```

### Environment variables

Create a `.env` file in the project root:

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=your-anon-key
```

---

## Key Features

- **Bilingual (NL/EN)** — full Dutch and English UI via `LanguageContext`
- **GDPR Consent Mode v2** — cookie banner defaults all signals to `denied`; updates Google Analytics and Ads only after explicit consent
- **Smooth section navigation** — navbar scrolls within the homepage or navigates and scrolls from any route
- **Auto-linking in posts** — bare URLs and `[text](url)` markdown in blog content render as clickable links
- **Affiliate monetization** — Skimlinks auto-converts eligible outbound links

---

## Deployment

The project deploys automatically via **Lovable** on every push to `main`.

To deploy manually: push to `main` and Lovable's CI picks it up within seconds.

---

## React 19 Compatibility Notes

This project runs on **React 19.2.x**. Key compatibility points:

- `react-day-picker` upgraded to **v9** (breaking API change from v8 — `classNames` keys renamed, `Chevron` component replaces `IconLeft`/`IconRight`)
- `@types/react` and `@types/react-dom` on v19 types
- All Radix UI, TanStack Query, React Router, React Hook Form packages confirmed compatible with React 19
- `next-themes`, `vaul`, `embla-carousel`, `recharts`, `sonner` all resolve cleanly under React 19 with `--legacy-peer-deps`
