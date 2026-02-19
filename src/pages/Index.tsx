import { Navbar } from "@/components/Navbar";
import { Hero } from "@/components/Hero";
import { BlogSection } from "@/components/BlogSection";
import { AboutSection } from "@/components/AboutSection";
import { ContactSection } from "@/components/ContactSection";
import { NewsletterSection } from "@/components/NewsletterSection";
import { Footer } from "@/components/Footer";

const Index = () => {
  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <main>
        <Hero />
        <BlogSection />
        <AboutSection />
        <ContactSection />
        <NewsletterSection />
      </main>
      <Footer />
    </div>
  );
};

export default Index;
