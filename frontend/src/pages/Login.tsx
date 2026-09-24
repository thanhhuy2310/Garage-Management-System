import { FormEvent, useState } from "react";
import { authApi, type LoginResponse } from "../api/auth";
import { errorMessage } from "../api/client";
import { readRememberedUsername, rememberUsername } from "../api/session";
import AuthLayout from "../components/auth/AuthLayout";
import { Icons } from "../components/ui";

interface LoginProps {
  onLogin: (response: LoginResponse, remember: boolean) => void;
  onBack: () => void;
  onRegister: () => void;
}

export default function Login({ onLogin, onBack, onRegister }: LoginProps) {
  const rememberedUsername = readRememberedUsername();
  const [username, setUsername] = useState(rememberedUsername);
  const [password, setPassword] = useState("");
  const [remember, setRemember] = useState(Boolean(rememberedUsername));
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [showPassword, setShowPassword] = useState(false);

  const handleUsernameChange = (value: string) => {
    setUsername(value);
    rememberUsername(value, remember);
  };

  const handleRememberChange = (checked: boolean) => {
    setRemember(checked);
    rememberUsername(username, checked);
  };

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    if (!username.trim() || !password) {
      setError("Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu.");
      return;
    }

    setError("");
    setLoading(true);
    try {
      const response = await authApi.login({ username: username.trim(), password });
      rememberUsername(username, remember);
      onLogin(response, remember);
    } catch (loginError) {
      setError(errorMessage(
        loginError,
        "Chưa kết nối được backend. Hãy đợi Garage Backend khởi động xong rồi thử lại.",
      ));
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthLayout>
      <h2 className="mb-1 text-2xl font-semibold text-foreground">Đăng nhập</h2>
      <p className="mb-7 text-sm text-muted-foreground">Hệ thống quản lý gara sửa chữa ô tô</p>

      <form onSubmit={handleSubmit} className="space-y-5">
        <div>
          <label htmlFor="username" className="mb-1.5 block text-sm font-medium text-slate-700">Tên đăng nhập</label>
          <input id="username" value={username} onChange={(event) => handleUsernameChange(event.target.value)} autoComplete="username" className="h-11 w-full rounded-md border border-border bg-surface px-4 text-base text-foreground shadow-sm transition-all hover:border-slate-400 focus:border-ring focus:ring-2 focus:ring-ring/15 sm:text-sm" />
        </div>
        <div>
          <label htmlFor="password" className="mb-1.5 block text-sm font-medium text-slate-700">Mật khẩu</label>
          <div className="relative">
            <input id="password" type={showPassword ? "text" : "password"} value={password} onChange={(event) => setPassword(event.target.value)} autoComplete="current-password" className="h-11 w-full rounded-md border border-border bg-surface px-4 pr-12 text-base text-foreground shadow-sm transition-all hover:border-slate-400 focus:border-ring focus:ring-2 focus:ring-ring/15 sm:text-sm" />
            <button
              type="button"
              onClick={() => setShowPassword((visible) => !visible)}
              className="absolute right-0 top-1/2 flex h-11 w-11 -translate-y-1/2 items-center justify-center rounded-md text-slate-500 transition-colors hover:bg-secondary hover:text-primary"
              aria-label={showPassword ? "Ẩn mật khẩu" : "Hiện mật khẩu"}
              aria-pressed={showPassword}
            >
              <span aria-hidden="true" className="scale-110">{showPassword ? Icons.eyeOff : Icons.eye}</span>
            </button>
          </div>
        </div>

        <div className="flex items-center">
          <label className="flex min-h-11 cursor-pointer items-center gap-2">
            <input type="checkbox" checked={remember} onChange={(event) => handleRememberChange(event.target.checked)} className="h-4 w-4 cursor-pointer accent-primary" />
            <span className="text-sm text-slate-600">Ghi nhớ đăng nhập</span>
          </label>
        </div>

        {error && <p className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger" role="alert">{error}</p>}

        <button type="submit" disabled={loading} className="flex h-11 w-full items-center justify-center gap-2 rounded-md bg-primary text-sm font-semibold text-primary-foreground transition-all hover:bg-primary-hover disabled:cursor-wait disabled:opacity-70">
          {loading && <span className="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" aria-hidden="true" />}
          {loading ? "Đang đăng nhập..." : "Đăng nhập"}
        </button>
      </form>

      <p className="mt-5 text-center text-sm text-muted-foreground">
        Chưa có tài khoản?{" "}
        <button type="button" onClick={onRegister} className="min-h-11 rounded-md px-1 font-semibold text-primary hover:underline">
          Đăng ký ngay
        </button>
      </p>

      <button
        type="button"
        onClick={onBack}
        className="mt-2 inline-flex min-h-11 items-center gap-2 rounded-md text-sm font-medium text-muted-foreground transition-all hover:text-primary"
      >
        <span aria-hidden="true">{Icons.arrowLeft}</span> Về trang chủ
      </button>
    </AuthLayout>
  );
}
