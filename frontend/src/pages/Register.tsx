import { FormEvent, useState } from "react";
import { authApi, type LoginResponse } from "../api/auth";
import { errorMessage } from "../api/client";
import { rememberUsername } from "../api/session";
import AuthLayout from "../components/auth/AuthLayout";
import { Icons } from "../components/ui";

interface RegisterProps {
  onRegistered: (response: LoginResponse, remember: boolean) => void;
  onLogin: () => void;
}

const INPUT_CLASS = "h-11 w-full rounded-md border border-border bg-surface px-4 text-base text-foreground shadow-sm transition-all hover:border-slate-400 focus:border-ring focus:ring-2 focus:ring-ring/15 sm:text-sm";

export default function Register({ onRegistered, onLogin }: RegisterProps) {
  const [fullName, setFullName] = useState("");
  const [phone, setPhone] = useState("");
  const [email, setEmail] = useState("");
  const [address, setAddress] = useState("");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    if (!fullName.trim() || !phone.trim() || !username.trim() || !password) {
      setError("Vui lòng nhập đầy đủ các trường bắt buộc.");
      return;
    }
    if (password.length < 8) {
      setError("Mật khẩu phải có ít nhất 8 ký tự.");
      return;
    }
    if (password !== confirmPassword) {
      setError("Mật khẩu xác nhận chưa khớp.");
      return;
    }

    setError("");
    setLoading(true);
    try {
      const response = await authApi.register({
        fullName: fullName.trim(),
        phone: phone.trim(),
        email: email.trim() || undefined,
        address: address.trim() || undefined,
        username: username.trim(),
        password,
      });
      rememberUsername(username, true);
      onRegistered(response, true);
    } catch (registerError) {
      setError(errorMessage(
        registerError,
        "Chưa kết nối được backend. Hãy đợi Garage Backend khởi động xong rồi thử lại.",
      ));
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthLayout width="max-w-[520px]">
      <h2 className="mb-1 text-2xl font-semibold text-foreground">Tạo tài khoản khách hàng</h2>
      <p className="mb-6 text-sm text-muted-foreground">Đăng ký để đặt lịch và theo dõi quá trình sửa chữa xe.</p>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="grid gap-4 sm:grid-cols-2">
          <div>
            <label htmlFor="register-full-name" className="mb-1.5 block text-sm font-medium text-slate-700">Họ và tên <span className="text-danger">*</span></label>
            <input id="register-full-name" value={fullName} onChange={(event) => setFullName(event.target.value)} autoComplete="name" className={INPUT_CLASS} />
          </div>
          <div>
            <label htmlFor="register-phone" className="mb-1.5 block text-sm font-medium text-slate-700">Số điện thoại <span className="text-danger">*</span></label>
            <input id="register-phone" type="tel" inputMode="tel" value={phone} onChange={(event) => setPhone(event.target.value)} autoComplete="tel" className={INPUT_CLASS} />
          </div>
        </div>

        <div className="grid gap-4 sm:grid-cols-2">
          <div>
            <label htmlFor="register-email" className="mb-1.5 block text-sm font-medium text-slate-700">Email</label>
            <input id="register-email" type="email" value={email} onChange={(event) => setEmail(event.target.value)} autoComplete="email" className={INPUT_CLASS} />
          </div>
          <div>
            <label htmlFor="register-address" className="mb-1.5 block text-sm font-medium text-slate-700">Địa chỉ</label>
            <input id="register-address" value={address} onChange={(event) => setAddress(event.target.value)} autoComplete="street-address" className={INPUT_CLASS} />
          </div>
        </div>

        <div>
          <label htmlFor="register-username" className="mb-1.5 block text-sm font-medium text-slate-700">Tên đăng nhập <span className="text-danger">*</span></label>
          <input id="register-username" value={username} onChange={(event) => setUsername(event.target.value)} autoComplete="username" minLength={4} className={INPUT_CLASS} />
        </div>

        <div className="grid gap-4 sm:grid-cols-2">
          <PasswordField id="register-password" label="Mật khẩu" value={password} onChange={setPassword} visible={showPassword} onToggle={() => setShowPassword((value) => !value)} autoComplete="new-password" />
          <PasswordField id="register-confirm-password" label="Xác nhận mật khẩu" value={confirmPassword} onChange={setConfirmPassword} visible={showConfirmPassword} onToggle={() => setShowConfirmPassword((value) => !value)} autoComplete="new-password" />
        </div>
        <p className="-mt-1 text-xs text-muted-foreground">Mật khẩu cần từ 8 đến 72 ký tự.</p>

        {error && <p className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger" role="alert">{error}</p>}

        <button type="submit" disabled={loading} className="flex h-11 w-full items-center justify-center gap-2 rounded-md bg-primary text-sm font-semibold text-primary-foreground transition-all hover:bg-primary-hover disabled:cursor-wait disabled:opacity-70">
          {loading && <span className="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" aria-hidden="true" />}
          {loading ? "Đang tạo tài khoản..." : "Đăng ký"}
        </button>
      </form>

      <p className="mt-5 text-center text-sm text-muted-foreground">
        Đã có tài khoản?{" "}
        <button type="button" onClick={onLogin} className="min-h-11 rounded-md px-1 font-semibold text-primary hover:underline">
          Đăng nhập
        </button>
      </p>
    </AuthLayout>
  );
}

function PasswordField({ id, label, value, onChange, visible, onToggle, autoComplete }: {
  id: string;
  label: string;
  value: string;
  onChange: (value: string) => void;
  visible: boolean;
  onToggle: () => void;
  autoComplete: string;
}) {
  return (
    <div>
      <label htmlFor={id} className="mb-1.5 block text-sm font-medium text-slate-700">{label} <span className="text-danger">*</span></label>
      <div className="relative">
        <input id={id} type={visible ? "text" : "password"} value={value} onChange={(event) => onChange(event.target.value)} autoComplete={autoComplete} minLength={8} className={`${INPUT_CLASS} pr-12`} />
        <button
          type="button"
          onClick={onToggle}
          className="absolute right-0 top-1/2 flex h-11 w-11 -translate-y-1/2 items-center justify-center rounded-md text-slate-500 transition-colors hover:bg-secondary hover:text-primary"
          aria-label={visible ? `Ẩn ${label.toLowerCase()}` : `Hiện ${label.toLowerCase()}`}
          aria-pressed={visible}
        >
          <span aria-hidden="true" className="scale-110">{visible ? Icons.eyeOff : Icons.eye}</span>
        </button>
      </div>
    </div>
  );
}
