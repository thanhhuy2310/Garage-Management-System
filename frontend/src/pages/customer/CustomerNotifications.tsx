import { useMemo, useState } from "react";
import { Card, Icons } from "../../components/ui";
import { thongBao } from "../../mock/schemaData";

const CUSTOMER_ID = "KH001";

const TYPE_META: Record<string, { icon: React.ReactNode; tint: string; label: string }> = {
  appointment: { icon: Icons.calendar, tint: "bg-info-soft text-info", label: "Lịch hẹn" },
  repair: { icon: Icons.wrench, tint: "bg-primary-soft text-primary", label: "Sửa chữa" },
  payment: { icon: Icons.creditCard, tint: "bg-success-soft text-success", label: "Thanh toán" },
  parts: { icon: Icons.package, tint: "bg-warning-soft text-warning", label: "Phụ tùng" },
};

export default function CustomerNotifications() {
  const mine = useMemo(() => thongBao.filter((n) => n.MaKhachHang === CUSTOMER_ID), []);
  const [readIds, setReadIds] = useState<string[]>([]);
  const unreadCount = mine.filter((n) => !n.DaDoc && !readIds.includes(n.MaThongBao)).length;

  return (
    <div className="space-y-6">
      <div className="page-toolbar">
        <div>
          <h2 className="ui-section-title">Thông báo</h2>
          <p className="ui-secondary-text text-sm">
            {unreadCount > 0 ? `${unreadCount} chưa đọc` : "Đã đọc hết"} · gồm nhắc lịch bảo dưỡng định kỳ
          </p>
        </div>
        {unreadCount > 0 && (
          <button
            type="button"
            onClick={() => setReadIds(mine.map((n) => n.MaThongBao))}
            className="min-h-11 rounded-md border border-border bg-surface px-4 text-sm font-semibold text-primary transition-all hover:bg-surface-subtle"
          >
            Đánh dấu đã đọc hết
          </button>
        )}
      </div>

      {mine.length === 0 ? (
        <Card className="p-10 text-center">
          <p className="ui-card-title">Chưa có thông báo</p>
          <p className="ui-secondary-text mt-1 text-sm">Lịch hẹn, báo giá và nhắc bảo dưỡng sẽ hiện tại đây.</p>
        </Card>
      ) : (
        <ul className="space-y-3">
          {mine.map((notice) => {
            const unread = !notice.DaDoc && !readIds.includes(notice.MaThongBao);
            const meta = TYPE_META[notice.LoaiThongBao] ?? { icon: Icons.info, tint: "bg-muted text-muted-foreground", label: "Chung" };
            return (
              <li key={notice.MaThongBao}>
                <button
                  type="button"
                  onClick={() => setReadIds((ids) => (ids.includes(notice.MaThongBao) ? ids : [...ids, notice.MaThongBao]))}
                  className={`flex w-full items-start gap-4 rounded-lg border bg-white p-4 text-left transition-all hover:border-slate-300 ${
                    unread ? "border-info/30 bg-info-soft/40" : "border-border"
                  }`}
                >
                  <span className={`flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-lg ${meta.tint}`} aria-hidden="true">
                    {meta.icon}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="flex items-center gap-2">
                      <span className="truncate text-sm font-semibold text-foreground">{notice.TieuDe}</span>
                      {unread && <span className="h-2 w-2 flex-shrink-0 rounded-full bg-info" aria-label="Chưa đọc" />}
                    </span>
                    <span className="mt-1 block text-sm leading-relaxed text-slate-600">{notice.NoiDung}</span>
                    <span className="mt-1 block text-xs text-slate-400">
                      {meta.label} · {notice.ThoiGian.slice(0, 16).replace("T", " ")}
                    </span>
                  </span>
                </button>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
