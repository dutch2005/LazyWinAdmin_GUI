export interface BlogPost {
  id: string;
  slug: string;
  category: "ai" | "news" | "tutorials" | "tools";
  date: string;
  readTime: number;
  featured?: boolean;
  title: { nl: string; en: string };
  excerpt: { nl: string; en: string };
  image?: string;
}

export const blogPosts: BlogPost[] = [
  {
    id: "1",
    slug: "ai-agents-2025",
    category: "ai",
    date: "2025-02-15",
    readTime: 6,
    featured: true,
    title: {
      nl: "AI Agents in 2025: Autonome software die écht werkt",
      en: "AI Agents in 2025: Autonomous software that actually works",
    },
    excerpt: {
      nl: "Van LLM-wrappers naar volwaardige autonome agenten — hoe de AI-wereld in een stroomversnelling is geraakt en wat dat betekent voor IT-professionals.",
      en: "From LLM wrappers to fully autonomous agents — how the AI world has accelerated and what that means for IT professionals.",
    },
  },
  {
    id: "2",
    slug: "n8n-workflow-automatisering",
    category: "ai",
    date: "2025-02-10",
    readTime: 8,
    title: {
      nl: "Automatiseer je workflow met n8n: Een praktische gids",
      en: "Automate your workflow with n8n: A practical guide",
    },
    excerpt: {
      nl: "n8n maakt het eenvoudig om krachtige automatiseringen te bouwen zonder code. In dit artikel laat ik zien hoe ik mijn dagelijkse IT-taken heb geautomatiseerd.",
      en: "n8n makes it easy to build powerful automations without code. In this article I show how I automated my daily IT tasks.",
    },
  },
  {
    id: "3",
    slug: "microsoft-copilot-review",
    category: "news",
    date: "2025-02-05",
    readTime: 5,
    title: {
      nl: "Microsoft Copilot voor IT-beheerders: Mijn eerlijke review",
      en: "Microsoft Copilot for IT admins: My honest review",
    },
    excerpt: {
      nl: "Na maanden werken met Copilot in een enterprise-omgeving deel ik mijn ervaringen, de sterke punten en de frustraties.",
      en: "After months of working with Copilot in an enterprise environment, I share my experiences, the strengths and the frustrations.",
    },
  },
  {
    id: "4",
    slug: "powershell-ai-integratie",
    category: "tutorials",
    date: "2025-01-28",
    readTime: 10,
    title: {
      nl: "PowerShell + AI: Slimme scripts schrijven in 2025",
      en: "PowerShell + AI: Writing smart scripts in 2025",
    },
    excerpt: {
      nl: "Gebruik AI-modellen rechtstreeks vanuit PowerShell om complexe systeembeheer-taken te automatiseren. Inclusief voorbeeldcode.",
      en: "Use AI models directly from PowerShell to automate complex system administration tasks. Includes sample code.",
    },
  },
  {
    id: "5",
    slug: "beste-it-tools-2025",
    category: "tools",
    date: "2025-01-20",
    readTime: 7,
    title: {
      nl: "Mijn top 10 IT-tools voor 2025",
      en: "My top 10 IT tools for 2025",
    },
    excerpt: {
      nl: "Van monitoring tot automatisering: de tools die mijn werk als IT-professional hebben getransformeerd en die ik dagelijks gebruik.",
      en: "From monitoring to automation: the tools that have transformed my work as an IT professional and that I use daily.",
    },
  },
  {
    id: "6",
    slug: "cloud-migratie-valkuilen",
    category: "news",
    date: "2025-01-12",
    readTime: 9,
    title: {
      nl: "Cloud migratie: De 5 grootste valkuilen (en hoe je ze vermijdt)",
      en: "Cloud migration: The 5 biggest pitfalls (and how to avoid them)",
    },
    excerpt: {
      nl: "Na tientallen cloud-migraties heb ik de meest voorkomende fouten gezien. Dit zijn de lessen die elke IT-afdeling zou moeten kennen.",
      en: "After dozens of cloud migrations, I've seen the most common mistakes. These are the lessons every IT department should know.",
    },
  },
];
