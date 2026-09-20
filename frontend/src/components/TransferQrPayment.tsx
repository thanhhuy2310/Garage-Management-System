import { useEffect, useMemo, useState } from "react";
import { QRCodeSVG } from "qrcode.react";
import { Button, Icons } from "./ui";

const QR_VALIDITY_SECONDS = 15 * 60;

const BANK = {
  name: "MB Bank",
  bin: "970422",
  account: "0123456789",
  accountName: "GARA O TO THANH CONG",
};

const qrField = (id: string, value: string) => `${id}${String(value.length).padStart(2, "0")}${value}`;

const crc16 = (value: string) => {
  let crc = 0xffff;
  for (let index = 0; index < value.length; index += 1) {
    crc ^= value.charCodeAt(index) << 8;
    for (let bit = 0; bit < 8; bit += 1) {
      crc = crc & 0x8000 ? (crc << 1) ^ 0x1021 : crc << 1;
      crc &= 0xffff;
    }
  }
  return crc.toString(16).toUpperCase().padStart(4, "0");
};

export const buildVietQrPayload = (amount: number, paymentContent: string) => {
  const beneficiary = qrField("00", BANK.bin) + qrField("01", BANK.account);
  const merchantAccount =
    qrField("00", "A000000727") +
    qrField("01", beneficiary) +
    qrField("02", "QRIBFTTA");
  const additionalData = qrField("08", paymentContent);
  const payload = [
    qrField("00", "01"),
    qrField("01", "12"),
    qrField("38", merchantAccount),
    qrField("53", "704"),
    qrField("54", String(Math.round(amount))),
    qrField("58", "VN"),
    qrField("62", additionalData),
    "6304",
  ].join("");

  return `${payload}${crc16(payload)}`;
};

const formatCountdown = (seconds: number) => {
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;
  return `${String(minutes).padStart(2, "0")}:${String(remainingSeconds).padStart(2, "0")}`;
};

interface TransferQrPaymentProps {
  amount: number;
  amountLabel: string;
  invoiceId: string;
  onValidityChange: (valid: boolean) => void;
}

export default function TransferQrPayment({ amount, amountLabel, invoiceId, onValidityChange }: TransferQrPaymentProps) {
  const [issuedAt, setIssuedAt] = useState(() => Date.now());
  const [secondsLeft, setSecondsLeft] = useState(QR_VALIDITY_SECONDS);
  const expiresAt = issuedAt + QR_VALIDITY_SECONDS * 1000;
  const reference = String(issuedAt).slice(-6);
  const paymentContent = `TC ${invoiceId} ${reference}`;
  const qrValue = useMemo(() => buildVietQrPayload(amount, paymentContent), [amount, paymentContent]);
  const expired = secondsLeft <= 0;
  const nearlyExpired = secondsLeft <= 60 && !expired;
  const progress = Math.max(0, Math.min(100, (secondsLeft / QR_VALIDITY_SECONDS) * 100));

  useEffect(() => {
    const updateCountdown = () => {
      setSecondsLeft(Math.max(0, Math.ceil((expiresAt - Date.now()) / 1000)));
    };

    updateCountdown();
    const timer = window.setInterval(updateCountdown, 1000);
    return () => window.clearInterval(timer);
  }, [expiresAt]);

  useEffect(() => {
    onValidityChange(!expired);
  }, [expired, onValidityChange]);

  const renewQr = () => {
    setIssuedAt(Date.now());
    setSecondsLeft(QR_VALIDITY_SECONDS);
  };

  const expiryLabel = new Intl.DateTimeFormat("vi-VN", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  }).format(expiresAt);

  return (
    <section className="rounded-lg border border-border bg-surface-subtle p-4" aria-labelledby="transfer-qr-title">
      <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p id="transfer-qr-title" className="font-semibold text-foreground">Quét QR để chuyển khoản</p>
          <p className="mt-1 text-xs leading-5 text-muted-foreground">Mã VietQR đã bao gồm số tiền và nội dung thanh toán của hóa đơn.</p>
        </div>
        <div className={`flex min-h-11 items-center gap-2 rounded-md border px-3 py-2 text-sm font-semibold ${expired ? "border-danger/20 bg-danger-soft text-danger" : nearlyExpired ? "border-warning/20 bg-warning-soft text-warning" : "border-success/20 bg-success-soft text-success"}`}>
          <span aria-hidden="true">{Icons.clock}</span>
          <span>{expired ? "Đã hết hạn" : `Còn ${formatCountdown(secondsLeft)}`}</span>
        </div>
      </div>

      <div className="grid gap-5 sm:grid-cols-[240px_minmax(0,1fr)] sm:items-center">
        <div className="relative mx-auto grid w-full max-w-60 place-items-center overflow-hidden rounded-lg border border-border bg-white p-2 shadow-sm">
          <QRCodeSVG
            value={qrValue}
            size={224}
            level="M"
            marginSize={4}
            title={`QR chuyển khoản hóa đơn ${invoiceId}`}
            className={`h-auto w-full transition-opacity ${expired ? "opacity-15" : "opacity-100"}`}
          />
          {expired && (
            <div className="absolute inset-0 flex flex-col items-center justify-center gap-3 bg-white/90 p-4 text-center">
              <span aria-hidden="true" className="scale-125 text-danger">{Icons.alertCircle}</span>
              <div><p className="font-semibold text-foreground">QR đã hết hạn</p><p className="mt-1 text-xs text-muted-foreground">Tạo mã mới để tiếp tục.</p></div>
              <Button type="button" size="sm" className="min-h-11" onClick={renewQr}>Tạo QR mới</Button>
            </div>
          )}
        </div>

        <div className="min-w-0">
          <dl className="divide-y divide-border rounded-lg border border-border bg-white px-4">
            <div className="flex items-start justify-between gap-4 py-3"><dt className="text-xs text-muted-foreground">Ngân hàng</dt><dd className="text-right text-sm font-semibold text-foreground">{BANK.name}</dd></div>
            <div className="flex items-start justify-between gap-4 py-3"><dt className="text-xs text-muted-foreground">Số tài khoản</dt><dd className="mono text-right text-sm font-semibold text-foreground">{BANK.account}</dd></div>
            <div className="flex items-start justify-between gap-4 py-3"><dt className="text-xs text-muted-foreground">Chủ tài khoản</dt><dd className="text-right text-sm font-semibold text-foreground">{BANK.accountName}</dd></div>
            <div className="flex items-start justify-between gap-4 py-3"><dt className="text-xs text-muted-foreground">Số tiền</dt><dd className="text-right text-sm font-bold text-primary">{amountLabel}</dd></div>
            <div className="flex items-start justify-between gap-4 py-3"><dt className="text-xs text-muted-foreground">Nội dung</dt><dd className="mono break-all text-right text-sm font-semibold text-foreground">{paymentContent}</dd></div>
          </dl>

          <div className="mt-3">
            <div className="mb-1.5 flex items-center justify-between gap-3 text-xs text-muted-foreground">
              <span>Hiệu lực 15 phút</span>
              <time dateTime={new Date(expiresAt).toISOString()}>Hết hạn lúc {expiryLabel}</time>
            </div>
            <div className="h-1.5 overflow-hidden rounded-full bg-muted" role="progressbar" aria-label="Thời gian còn hiệu lực của mã QR" aria-valuemin={0} aria-valuemax={QR_VALIDITY_SECONDS} aria-valuenow={secondsLeft}>
              <div className={`h-full w-full origin-left rounded-full transition-transform duration-1000 motion-reduce:transition-none ${expired ? "bg-danger" : nearlyExpired ? "bg-warning" : "bg-success"}`} style={{ transform: `scaleX(${progress / 100})` }} />
            </div>
          </div>
        </div>
      </div>

      <p className="mt-4 rounded-md border border-info/20 bg-info-soft px-3 py-2 text-xs leading-5 text-info">
        Kiểm tra đúng số tiền và nội dung trước khi xác nhận. Thông tin tài khoản hiện là dữ liệu demo và cần thay bằng tài khoản gara khi triển khai thực tế.
      </p>
      <p className="sr-only" aria-live="polite">{expired ? "Mã QR chuyển khoản đã hết hạn. Hãy tạo mã QR mới để tiếp tục." : ""}</p>
    </section>
  );
}
