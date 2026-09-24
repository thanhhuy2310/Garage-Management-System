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
        <div className="absolute inset-0" aria-hidden="true">
          <img
            src="/images/garage-workshop.webp"
            alt=""
            width="1536"
            height="1024"
            decoding="async"
            className="h-full w-full object-cover object-center"
          />
          <div className="absolute inset-0 bg-brand-dark/45" />
          <div className="absolute inset-0 bg-gradient-to-b from-brand-dark/80 via-transparent to-brand-dark/95" />
        </div>

        <div className="relative z-10 flex w-fit items-center gap-3 rounded-xl border border-white/15 bg-brand-dark/75 p-3 shadow-lg shadow-black/10">
          <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-accent text-white" aria-hidden="true"><span className="scale-125">{Icons.car}</span></div>
          <div>
            <p className="text-lg font-bold leading-tight text-white">{GARAGE_NAME}</p>
            <p className="text-xs text-white/70">Hệ thống quản lý gara</p>
          </div>
        </div>

        <div className="relative z-10 grid grid-cols-2 gap-x-5 gap-y-3 rounded-xl border border-white/15 bg-brand-dark/80 p-5 shadow-xl shadow-black/15">
          {FEATURES.map((feature) => (
            <div key={feature.text} className="flex items-center gap-2 text-sm text-white/85">
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
