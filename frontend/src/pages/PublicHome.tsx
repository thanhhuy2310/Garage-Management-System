import PublicHeader, { type PublicPageKey } from "../components/PublicHeader";
import PublicAbout from "../components/PublicAbout";
import PublicFooter from "../components/PublicFooter";
import PublicHero from "../components/PublicHero";
import PublicParts from "../components/PublicParts";
import PublicProcess from "../components/PublicProcess";
import PublicServices from "../components/PublicServices";
import PublicAboutPage from "./PublicAboutPage";
import PublicContactPage from "./PublicContactPage";
import PublicPartsPage from "./PublicPartsPage";
import PublicServicesPage from "./PublicServicesPage";

const PAGE_NOTES: Record<PublicPageKey, { title: string; note: string }> = {
  home: { title: "Trang chủ", note: "Hero, dịch vụ nổi bật, quy trình và các section khác sẽ được hoàn thiện ở các phần tiếp theo." },
  about: { title: "Giới thiệu", note: "Nội dung trang giới thiệu gara sẽ được hoàn thiện ở phần trang About." },
  services: { title: "Dịch vụ", note: "Nội dung trang dịch vụ sẽ được hoàn thiện ở phần trang Services." },
  parts: { title: "Phụ tùng", note: "Nội dung trang phụ tùng sẽ được hoàn thiện ở phần trang Parts." },
  contact: { title: "Liên hệ", note: "Nội dung trang liên hệ sẽ được hoàn thiện ở phần trang Contact." },
};

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
  const meta = PAGE_NOTES[page];
  return (
    <div className="min-h-screen bg-background">
      <PublicHeader active={page} onNavigate={onNavigate} onLogin={onLogin} onBook={onBook} />
      {page === "home" ? (
        <main>
          <PublicHero onBook={onBook} onViewServices={() => onNavigate("services")} />
          <PublicServices onBook={onBook} onViewAll={() => onNavigate("services")} />
          <PublicProcess onBook={onBook} />
          <PublicAbout onNavigateAbout={() => onNavigate("about")} />
          <PublicParts onBook={onBook} onViewAll={() => onNavigate("parts")} />
          <PublicFooter onNavigate={onNavigate} onBook={onBook} />
        </main>
      ) : (
        <main className="mx-auto w-full max-w-6xl px-4 py-16 text-center">
          <p className="ui-section-title">{meta.title}</p>
          <p className="ui-secondary-text mx-auto mt-2 max-w-xl text-sm">{meta.note}</p>
        </main>
      )}
    </div>
  );
}
