import { useEffect, useRef } from "react";
import PublicHeader, { type PublicPageKey } from "../components/PublicHeader";
import PublicAbout from "../components/PublicAbout";
import PublicFooter from "../components/PublicFooter";
import PublicHero from "../components/PublicHero";
import PublicParts from "../components/PublicParts";
import PublicProcess from "../components/PublicProcess";
import PublicServices from "../components/PublicServices";
import PublicTestimonials from "../components/PublicTestimonials";
import PublicAboutPage from "./PublicAboutPage";
import PublicContactPage from "./PublicContactPage";
import PublicPartsPage from "./PublicPartsPage";
import PublicServicesPage from "./PublicServicesPage";

interface PublicHomeProps {
  page: PublicPageKey;
  onNavigate: (page: PublicPageKey) => void;
  onLogin: () => void;
  onBook: () => void;
}

export default function PublicHome({ page, onNavigate, onLogin, onBook }: PublicHomeProps) {
  const homeRef = useRef<HTMLElement>(null);

  useEffect(() => {
    if (page !== "home") return;
    const root = homeRef.current;
    if (!root) return;
    const sections = Array.from(root.querySelectorAll<HTMLElement>(".public-reveal"));
    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    if (reduceMotion || !("IntersectionObserver" in window)) {
      sections.forEach((section) => section.classList.add("is-visible"));
      return;
    }

    root.classList.add("motion-ready");
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      });
    }, { threshold: 0.12, rootMargin: "0px 0px -8%" });

    sections.forEach((section) => observer.observe(section));
    return () => observer.disconnect();
  }, [page]);

  if (page === "about") {
    return <div key={page} className="public-page-enter"><PublicAboutPage onNavigate={onNavigate} onLogin={onLogin} onBook={onBook} /></div>;
  }
  if (page === "contact") {
    return <div key={page} className="public-page-enter"><PublicContactPage onNavigate={onNavigate} onLogin={onLogin} onBook={onBook} /></div>;
  }
  if (page === "services") {
    return <div key={page} className="public-page-enter"><PublicServicesPage onNavigate={onNavigate} onLogin={onLogin} onBook={onBook} /></div>;
  }
  if (page === "parts") {
    return <div key={page} className="public-page-enter"><PublicPartsPage onNavigate={onNavigate} onLogin={onLogin} onBook={onBook} /></div>;
  }
  return (
    <div className="min-h-screen bg-background">
      <PublicHeader active={page} onNavigate={onNavigate} onLogin={onLogin} onBook={onBook} />
      <main ref={homeRef} className="public-home">
        <PublicHero onBook={onBook} onViewServices={() => onNavigate("services")} />
        <PublicServices onBook={onBook} onViewAll={() => onNavigate("services")} />
        <PublicProcess onBook={onBook} />
        <PublicAbout onNavigateAbout={() => onNavigate("about")} />
        <PublicParts onBook={onBook} onViewAll={() => onNavigate("parts")} />
        <PublicTestimonials />
        <PublicFooter onNavigate={onNavigate} onBook={onBook} />
      </main>
    </div>
  );
}
