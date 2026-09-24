import type { ReactNode } from "react";
import { GARAGE_NAME } from "../../data";
import { Icons } from "../ui";

const FEATURES = [
  { icon: Icons.calendar, text: "Quản lý lịch hẹn" },
  { icon: Icons.wrench, text: "Theo dõi sửa chữa" },
  { icon: Icons.package, text: "Quản lý kho" },
  { icon: Icons.barChart, text: "Báo cáo thống kê" },
];

export default function AuthLayout({ children, width = "max-w-[420px]" }: { children: ReactNode; width?: string }) {
  return (
    <div className="flex min-h-dvh bg-background">
      <section className="relative hidden w-[46%] flex-col justify-between overflow-hidden bg-brand-dark p-10 2xl:p-12 xl:flex">
        <div className="absolute inset-0 overflow-hidden" aria-hidden="true">
          <div className="absolute -right-20 -top-20 h-80 w-80 rounded-full bg-white/5" />
          <div className="absolute -bottom-20 -left-20 h-96 w-96 rounded-full bg-white/5" />
          <div className="absolute bottom-1/3 right-1/4 h-48 w-48 rounded-full bg-amber-500/10" />
        </div>

        <div className="relative z-10 flex items-center gap-3">
          <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-accent text-white" aria-hidden="true"><span className="scale-125">{Icons.car}</span></div>
          <div>
            <p className="text-lg font-bold leading-tight text-white">{GARAGE_NAME}</p>
            <p className="text-xs text-white/50">Hệ thống quản lý gara</p>
          </div>
        </div>

        <div className="relative z-10 max-w-xl">
          <svg viewBox="0 0 400 200" className="mb-7 w-full max-w-lg opacity-90" aria-hidden="true">
            <g transform="translate(40, 60)">
              <path d="M60 80 L60 50 Q70 30 100 25 L240 25 Q270 30 280 50 L280 80 Z" fill="rgba(255,255,255,0.15)" stroke="rgba(255,255,255,0.4)" strokeWidth="2" />
              <path d="M80 50 Q90 20 120 15 L230 15 Q260 20 265 50 Z" fill="rgba(255,255,255,0.2)" stroke="rgba(255,255,255,0.3)" strokeWidth="1.5" />
              <path d="M95 47 Q100 28 120 23 L175 23 L175 47 Z" fill="rgba(255,255,255,0.3)" />
              <path d="M180 23 L230 23 Q250 28 255 47 L180 47 Z" fill="rgba(255,255,255,0.3)" />
              <circle cx="100" cy="83" r="20" fill="rgba(0,0,0,0.3)" stroke="rgba(255,255,255,0.4)" strokeWidth="2" />
              <circle cx="100" cy="83" r="10" fill="rgba(255,255,255,0.2)" />
              <circle cx="240" cy="83" r="20" fill="rgba(0,0,0,0.3)" stroke="rgba(255,255,255,0.4)" strokeWidth="2" />
              <circle cx="240" cy="83" r="10" fill="rgba(255,255,255,0.2)" />
              <ellipse cx="280" cy="60" rx="5" ry="8" fill="#f59e0b" opacity="0.8" />
            </g>
            <line x1="20" y1="162" x2="380" y2="162" stroke="rgba(255,255,255,0.2)" />
          </svg>
          <h1 className="mb-3 text-[28px] font-semibold leading-tight text-white 2xl:text-3xl">Quản lý công việc tại gara</h1>
          <p className="max-w-sm text-sm leading-relaxed text-white/60">
            Theo dõi lịch hẹn, tiếp nhận, sửa chữa, kho và hóa đơn trong cùng một hệ thống.
          </p>
        </div>

        <div className="relative z-10 grid grid-cols-2 gap-x-5 gap-y-3 border-t border-white/10 pt-6">
          {FEATURES.map((feature) => (
            <div key={feature.text} className="flex items-center gap-2 text-sm text-white/70">
              <span className="text-amber-300" aria-hidden="true">{feature.icon}</span><span>{feature.text}</span>
            </div>
          ))}
        </div>
      </section>

      <main className="flex flex-1 items-center justify-center overflow-y-auto bg-surface px-4 py-8 sm:p-8 lg:p-10">
        <div className={`w-full ${width}`}>
          <div className="mb-8 flex items-center gap-3 xl:hidden">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary text-white" aria-hidden="true">{Icons.car}</div>
            <p className="font-semibold text-primary">{GARAGE_NAME}</p>
          </div>
          {children}
        </div>
      </main>
    </div>
  );
}
