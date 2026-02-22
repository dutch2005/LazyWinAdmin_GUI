import { Helmet } from "react-helmet-async";

interface SEOHeadProps {
  title?: string;
  description?: string;
  image?: string;
  url?: string;
  type?: "website" | "article";
  article?: {
    publishedTime: string;
    author: string;
    category: string;
    tags?: string[];
  };
  jsonLd?: Record<string, unknown>;
}

const SITE_NAME = "Mike Maze | IT Adventures";
const DEFAULT_DESCRIPTION =
  "Mike Maze deelt IT-ervaringen, tech nieuws en AI automatisering tips via IT Adventures.";
const SITE_URL = "https://mike-maze-it-adventures.lovable.app";

export const SEOHead = ({
  title,
  description = DEFAULT_DESCRIPTION,
  image,
  url,
  type = "website",
  article,
  jsonLd,
}: SEOHeadProps) => {
  const fullTitle = title ? `${title} | ${SITE_NAME}` : SITE_NAME;
  const canonical = url ? `${SITE_URL}${url}` : SITE_URL;

  const defaultJsonLd = {
    "@context": "https://schema.org",
    "@type": "WebSite",
    name: SITE_NAME,
    url: SITE_URL,
    description: DEFAULT_DESCRIPTION,
    author: {
      "@type": "Person",
      name: "Michael Maertzdorf",
    },
  };

  const articleJsonLd = article
    ? {
        "@context": "https://schema.org",
        "@type": "BlogPosting",
        headline: title,
        description,
        image,
        url: canonical,
        datePublished: article.publishedTime,
        author: {
          "@type": "Person",
          name: article.author,
        },
        publisher: {
          "@type": "Organization",
          name: SITE_NAME,
        },
        articleSection: article.category,
        keywords: article.tags?.join(", "),
      }
    : null;

  const structuredData = jsonLd || articleJsonLd || defaultJsonLd;

  return (
    <Helmet>
      <title>{fullTitle}</title>
      <meta name="description" content={description} />
      <link rel="canonical" href={canonical} />

      {/* Open Graph */}
      <meta property="og:type" content={type} />
      <meta property="og:title" content={fullTitle} />
      <meta property="og:description" content={description} />
      <meta property="og:url" content={canonical} />
      <meta property="og:site_name" content={SITE_NAME} />
      {image && <meta property="og:image" content={image} />}

      {/* Article specific */}
      {article && (
        <meta property="article:published_time" content={article.publishedTime} />
      )}
      {article && (
        <meta property="article:author" content={article.author} />
      )}
      {article && (
        <meta property="article:section" content={article.category} />
      )}

      {/* Twitter Card */}
      <meta name="twitter:card" content={image ? "summary_large_image" : "summary"} />
      <meta name="twitter:title" content={fullTitle} />
      <meta name="twitter:description" content={description} />
      {image && <meta name="twitter:image" content={image} />}

      {/* JSON-LD */}
      <script type="application/ld+json">
        {JSON.stringify(structuredData)}
      </script>
    </Helmet>
  );
};
