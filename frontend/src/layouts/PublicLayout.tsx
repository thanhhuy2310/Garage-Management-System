import type { ReactNode } from "react";

interface PublicLayoutProps {
  children: ReactNode;
}

export default function PublicLayout({ children }: PublicLayoutProps) {
  return (
    <div className="min-h-screen bg-background text-foreground">
      <a href="#public-content" className="skip-link">Bỏ qua đến nội dung chính</a>
      <div id="public-content" tabIndex={-1}>{children}</div>
    </div>
  );
}
