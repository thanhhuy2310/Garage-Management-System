import React, { useState } from "react";
import { GARAGE_NAME } from "../data";

interface LoginProps {
  onLogin: () => void;
}

export default function Login({ onLogin }: LoginProps) {
  const [remember, setRemember] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setTimeout(() => { setLoading(false); onLogin(); }, 800);
  };

  return (
    <div className="min-h-screen flex bg-white">
      {/* Left panel – illustration */}
      <div className="hidden lg:flex flex-col justify-between w-[52%] bg-[#1e3a6e] relative overflow-hidden p-12">
        {/* Background pattern */}
        <div className="absolute inset-0 overflow-hidden">
          <div className="absolute -right-20 -top-20 w-80 h-80 bg-white/5 rounded-full" />
          <div className="absolute -left-20 -bottom-20 w-96 h-96 bg-white/5 rounded-full" />
          <div className="absolute right-1/4 bottom-1/3 w-48 h-48 bg-amber-500/10 rounded-full" />
        </div>

        {/* Logo */}
        <div className="relative z-10">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 bg-amber-500 rounded-2xl flex items-center justify-center">
              <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2">
                <path d="M5 17H3a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v9a2 2 0 0 1-2 2h-2"/>
                <circle cx="7.5" cy="17.5" r="2.5"/>
                <circle cx="17.5" cy="17.5" r="2.5"/>
              </svg>
            </div>
            <div>
              <p className="text-white font-bold text-lg leading-tight">{GARAGE_NAME}</p>
              <p className="text-white/50 text-xs">Hệ thống quản lý gara</p>
            </div>
          </div>
        </div>

        {/* Main content */}
        <div className="relative z-10">
          {/* Car illustration */}
          <div className="mb-10">
            <svg viewBox="0 0 400 200" className="w-full opacity-90">
              {/* Simple car SVG */}
              <g transform="translate(40, 60)">
                {/* Body */}
                <path d="M60 80 L60 50 Q70 30 100 25 L240 25 Q270 30 280 50 L280 80 Z" fill="rgba(255,255,255,0.15)" stroke="rgba(255,255,255,0.4)" strokeWidth="2"/>
                {/* Roof */}
                <path d="M80 50 Q90 20 120 15 L230 15 Q260 20 265 50 Z" fill="rgba(255,255,255,0.2)" stroke="rgba(255,255,255,0.3)" strokeWidth="1.5"/>
                {/* Windows */}
                <path d="M95 47 Q100 28 120 23 L175 23 L175 47 Z" fill="rgba(255,255,255,0.3)"/>
                <path d="M180 23 L230 23 Q250 28 255 47 L180 47 Z" fill="rgba(255,255,255,0.3)"/>
                {/* Wheels */}
                <circle cx="100" cy="83" r="20" fill="rgba(0,0,0,0.3)" stroke="rgba(255,255,255,0.4)" strokeWidth="2"/>
                <circle cx="100" cy="83" r="10" fill="rgba(255,255,255,0.2)"/>
                <circle cx="240" cy="83" r="20" fill="rgba(0,0,0,0.3)" stroke="rgba(255,255,255,0.4)" strokeWidth="2"/>
                <circle cx="240" cy="83" r="10" fill="rgba(255,255,255,0.2)"/>
                {/* Front light */}
                <ellipse cx="280" cy="60" rx="5" ry="8" fill="#f59e0b" opacity="0.8"/>
              </g>
              {/* Ground */}
              <line x1="20" y1="162" x2="380" y2="162" stroke="rgba(255,255,255,0.2)" strokeWidth="1"/>
            </svg>
          </div>

          <h1 className="text-3xl font-black text-white leading-tight mb-3">
            Quản lý gara<br />
            <span className="text-amber-400">thông minh & hiệu quả</span>
          </h1>
          <p className="text-white/60 text-sm leading-relaxed max-w-sm">
            Hệ thống quản lý toàn diện dành cho gara ô tô – từ tiếp nhận, sửa chữa đến bàn giao xe.
          </p>
        </div>

        {/* Features */}
        <div className="relative z-10 grid grid-cols-2 gap-3">
          {[
            { icon: "📅", text: "Quản lý lịch hẹn" },
            { icon: "🔧", text: "Theo dõi sửa chữa" },
            { icon: "📦", text: "Quản lý kho" },
            { icon: "📊", text: "Báo cáo thống kê" },
          ].map(f => (
            <div key={f.text} className="flex items-center gap-2 text-white/70 text-sm">
              <span>{f.icon}</span>
              <span>{f.text}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Right panel – form */}
      <div className="flex-1 flex items-center justify-center p-8">
        <div className="w-full max-w-md">
          {/* Mobile logo */}
          <div className="flex items-center gap-3 mb-8 lg:hidden">
            <div className="w-10 h-10 bg-[#1e3a6e] rounded-xl flex items-center justify-center">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2">
                <path d="M5 17H3a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v9a2 2 0 0 1-2 2h-2"/>
                <circle cx="7.5" cy="17.5" r="2.5"/>
                <circle cx="17.5" cy="17.5" r="2.5"/>
              </svg>
            </div>
            <p className="font-bold text-[#1e3a6e]">{GARAGE_NAME}</p>
          </div>

          <h2 className="text-2xl font-black text-slate-800 mb-1">Đăng nhập</h2>
          <p className="text-slate-500 text-sm mb-8">Hệ thống quản lý gara sửa chữa ô tô</p>

          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label className="text-sm font-medium text-slate-700 block mb-1.5">Tên đăng nhập</label>
              <input
                type="text"
                defaultValue="admin"
                placeholder="Nhập tên đăng nhập"
                className="w-full h-11 border border-[#dde3ec] rounded-xl px-4 text-sm bg-white focus:border-[#1e3a6e] focus:ring-2 focus:ring-[#1e3a6e]/10 focus:outline-none transition-all"
              />
            </div>
            <div>
              <label className="text-sm font-medium text-slate-700 block mb-1.5">Mật khẩu</label>
              <input
                type="password"
                defaultValue="password"
                placeholder="Nhập mật khẩu"
                className="w-full h-11 border border-[#dde3ec] rounded-xl px-4 text-sm bg-white focus:border-[#1e3a6e] focus:ring-2 focus:ring-[#1e3a6e]/10 focus:outline-none transition-all"
              />
            </div>

            <div className="flex items-center justify-between">
              <label className="flex items-center gap-2 cursor-pointer">
                <input type="checkbox" checked={remember} onChange={e => setRemember(e.target.checked)}
                  className="w-4 h-4 accent-[#1e3a6e] cursor-pointer" />
                <span className="text-sm text-slate-600">Ghi nhớ đăng nhập</span>
              </label>
              <button type="button" className="text-sm text-[#1e3a6e] font-medium hover:underline">Quên mật khẩu?</button>
            </div>

            <button type="submit" disabled={loading}
              className="w-full h-12 bg-[#1e3a6e] hover:bg-[#162d56] text-white rounded-xl font-semibold text-sm transition-all flex items-center justify-center gap-2 disabled:opacity-70">
              {loading ? (
                <>
                  <svg className="animate-spin w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/>
                  </svg>
                  Đang đăng nhập...
                </>
              ) : "Đăng nhập"}
            </button>
          </form>

          {/* Demo accounts */}
          <div className="mt-8 p-4 bg-slate-50 rounded-xl border border-[#dde3ec]">
            <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Tài khoản demo</p>
            <div className="space-y-2">
              {[
                { label: "Quản lý", user: "manager", pass: "••••••••" },
                { label: "KTV", user: "ktv.khoa", pass: "••••••••" },
                { label: "Tiếp nhận", user: "tiepnhan", pass: "••••••••" },
              ].map(acc => (
                <div key={acc.user} className="flex items-center justify-between text-xs">
                  <span className="font-medium text-slate-600">{acc.label}</span>
                  <span className="mono text-slate-400">{acc.user} / {acc.pass}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
