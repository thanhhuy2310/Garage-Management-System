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
  if (page === "about") {
    return <PublicAboutPage onNavigate={onNavigate} onLogin={onLogin} onBook={onBook} />;
  }
  if (page === "contact") {
    return <PublicContactPage onNavigate={onNavigate} onLogin={onLogin} onBook={onBook} />;
  }
  if (page === "services") {
    return <PublicServicesPage onNavigate={onNavigate} onLogin={onLogin} onBook={onBook} />;
  }
  if (page === "parts") {
    return <PublicPartsPage onNavigate={onNavigate} onLogin={onLogin} onBook={onBook} />;
  }
  return (
    <div className="min-h-screen bg-background">
      <PublicHeader active={page} onNavigate={onNavigate} onLogin={onLogin} onBook={onBook} />
      <main>
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
