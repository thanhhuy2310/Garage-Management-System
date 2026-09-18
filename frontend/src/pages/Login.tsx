import { FormEvent, useEffect, useState } from "react";
import { GARAGE_NAME } from "../data";
import { Icons } from "../components/ui";

interface LoginProps {
  onLogin: () => void;
  account: {
    label: string;
    username: string;
  };
}

const FEATURES = [
  { icon: Icons.calendar, text: "Quản lý lịch hẹn" },
  { icon: Icons.wrench, text: "Theo dõi sửa chữa" },
  { icon: Icons.package, text: "Quản lý kho" },
  { icon: Icons.barChart, text: "Báo cáo thống kê" },
];

export default function Login({ onLogin, account }: LoginProps) {
  const [username, setUsername] = useState(account.username);
  const [password, setPassword] = useState("demo123");
  const [remember, setRemember] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [showPassword, setShowPassword] = useState(false);

  useEffect(() => {
    setUsername(account.username);
    setPassword("demo123");
    setError("");
  }, [account.username]);

  const handleSubmit = (event: FormEvent) => {
    event.preventDefault();
    if (username.trim() !== account.username || password !== "demo123") {
      setError("Tên đăng nhập hoặc mật khẩu demo chưa đúng.");
      return;
    }
    setError("");
    setLoading(true);
    window.setTimeout(() => {
      setLoading(false);
      onLogin();
    }, 350);
  };

  return (
    <div className="flex min-h-dvh bg-white">
      <section className="relative hidden w-[50%] flex-col justify-between overflow-hidden bg-primary p-10 xl:p-12 lg:flex">
        <div className="absolute inset-0 overflow-hidden" aria-hidden="true">
          <div className="absolute -right-20 -top-20 h-80 w-80 rounded-full bg-white/5" />
          <div className="absolute -bottom-20 -left-20 h-96 w-96 rounded-full bg-white/5" />
          <div className="absolute bottom-1/3 right-1/4 h-48 w-48 rounded-full bg-amber-500/10" />
        </div>

        <div className="relative z-10 flex items-center gap-3">
          <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-amber-600">
            <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2">
              <path d="M5 17H3a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v9a2 2 0 0 1-2 2h-2" />
              <circle cx="7.5" cy="17.5" r="2.5" /><circle cx="17.5" cy="17.5" r="2.5" />
            </svg>
          </div>
          <div>
            <p className="text-lg font-bold leading-tight text-white">{GARAGE_NAME}</p>
            <p className="text-xs text-white/50">Hệ thống quản lý gara</p>
          </div>
        </div>

        <div className="relative z-10">
          <svg viewBox="0 0 400 200" className="mb-8 w-full opacity-90" aria-hidden="true">
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
          <h1 className="mb-3 text-3xl font-bold leading-tight text-white">
            Quản lý gara<br /><span className="text-amber-400">thông minh & hiệu quả</span>
          </h1>
          <p className="max-w-sm text-sm leading-relaxed text-white/60">
            Hệ thống quản lý toàn diện dành cho gara ô tô – từ tiếp nhận, sửa chữa đến bàn giao xe.
          </p>
        </div>

        <div className="relative z-10 grid grid-cols-2 gap-3">
          {FEATURES.map((feature) => (
            <div key={feature.text} className="flex items-center gap-2 text-sm text-white/70">
              <span className="text-amber-300" aria-hidden="true">{feature.icon}</span><span>{feature.text}</span>
            </div>
          ))}
        </div>
      </section>

      <main className="flex flex-1 items-center justify-center p-6 sm:p-8">
        <div className="w-full max-w-md">
          <div className="mb-8 flex items-center gap-3 lg:hidden">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#1e3a6e]">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2">
                <path d="M5 17H3a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v9a2 2 0 0 1-2 2h-2" />
                <circle cx="7.5" cy="17.5" r="2.5" /><circle cx="17.5" cy="17.5" r="2.5" />
              </svg>
            </div>
            <p className="font-bold text-[#1e3a6e]">{GARAGE_NAME}</p>
          </div>

          <h2 className="mb-1 text-2xl font-bold text-slate-900">Đăng nhập</h2>
          <p className="mb-2 text-sm text-slate-500">Hệ thống quản lý gara sửa chữa ô tô</p>
          <p className="mb-7 text-xs font-medium text-[#1e3a6e]">Vai trò đang chọn: {account.label}</p>

          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label htmlFor="username" className="mb-1.5 block text-sm font-medium text-slate-700">Tên đăng nhập</label>
              <input id="username" value={username} onChange={(event) => setUsername(event.target.value)} autoComplete="username" className="h-11 w-full rounded-md border border-border bg-white px-4 text-sm shadow-sm transition-all hover:border-slate-400 focus:border-blue-600 focus:ring-2 focus:ring-blue-600/15" />
            </div>
            <div>
              <label htmlFor="password" className="mb-1.5 block text-sm font-medium text-slate-700">Mật khẩu</label>
              <div className="relative">
                <input id="password" type={showPassword ? "text" : "password"} value={password} onChange={(event) => setPassword(event.target.value)} autoComplete="current-password" className="h-11 w-full rounded-md border border-border bg-white px-4 pr-16 text-sm shadow-sm transition-all hover:border-slate-400 focus:border-blue-600 focus:ring-2 focus:ring-blue-600/15" />
                <button type="button" onClick={() => setShowPassword((visible) => !visible)} className="absolute right-1 top-1/2 min-h-9 -translate-y-1/2 rounded-md px-3 text-xs font-semibold text-primary hover:bg-secondary" aria-label={showPassword ? "Ẩn mật khẩu" : "Hiện mật khẩu"}>{showPassword ? "Ẩn" : "Hiện"}</button>
              </div>
            </div>

            <div className="flex items-center justify-between">
              <label className="flex cursor-pointer items-center gap-2">
                <input type="checkbox" checked={remember} onChange={(event) => setRemember(event.target.checked)} className="h-4 w-4 cursor-pointer accent-[#1e3a6e]" />
                <span className="text-sm text-slate-600">Ghi nhớ đăng nhập</span>
              </label>
              <button type="button" className="text-sm font-medium text-[#1e3a6e] hover:underline">Quên mật khẩu?</button>
            </div>

            {error && <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-600" role="alert">{error}</p>}

            <button type="submit" disabled={loading} className="flex h-12 w-full items-center justify-center gap-2 rounded-md bg-primary text-sm font-semibold text-white transition-all hover:bg-[#102a4c] disabled:opacity-70">
              {loading ? "Đang đăng nhập..." : "Đăng nhập"}
            </button>
          </form>

          <div className="mt-8 rounded-lg border border-border bg-slate-50 p-4">
            <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">Tài khoản demo</p>
            <p className="text-xs text-slate-600"><strong>{account.label}:</strong> {account.username} / demo123</p>
            <p className="mt-2 text-[11px] leading-relaxed text-slate-400">Dùng nút chọn vai trò ở góc dưới để đổi actor trước khi đăng nhập.</p>
          </div>
        </div>
      </main>
    </div>
  );
}
