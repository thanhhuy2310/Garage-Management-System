import { useMemo, useState } from "react";
import { Badge, Card } from "../../components/ui";
import { baoGia, chiTietBaoGia, formatCurrency, phieuSuaChua, phieuTiepNhan, xe } from "../../mock/data";

const CUSTOMER_ID = "KH001";

export default function CustomerHistory() {
  const [expanded, setExpanded] = useState<string | null>(null);

  const completed = useMemo(
    () =>
      phieuSuaChua.filter((r) => {
        if (r.TrangThai !== "completed") return false;
        const reception = phieuTiepNhan.find((t) => t.MaTiepNhan === r.MaTiepNhan);
        return xe.find((v) => v.MaXe === reception?.MaXe)?.MaKhachHang === CUSTOMER_ID;
      }),
    [],
  );

  return (
    <div className="space-y-4">
      <div>
        <h2 className="ui-section-title">Lịch sử sửa chữa / bảo dưỡng</h2>
        <p className="ui-secondary-text text-sm">{completed.length} lần đã hoàn tất</p>
      </div>

      {completed.length === 0 ? (
        <Card className="p-10 text-center">
          <p className="ui-card-title">Chưa có lịch sử sửa chữa</p>
          <p className="ui-secondary-text mt-1 text-sm">Các phiếu sửa chữa hoàn tất sẽ hiển thị tại đây kèm chi phí.</p>
        </Card>
      ) : (
        <ul className="space-y-4">
          {completed.map((repair) => {
            const reception = phieuTiepNhan.find((t) => t.MaTiepNhan === repair.MaTiepNhan);
            const vehicle = xe.find((v) => v.MaXe === reception?.MaXe);
            const quotation = baoGia.find((q) => q.MaPhieuSuaChua === repair.MaPhieuSuaChua);
            const lines = chiTietBaoGia.filter((line) => line.MaBaoGia === quotation?.MaBaoGia);
            const open = expanded === repair.MaPhieuSuaChua;
            return (
              <li key={repair.MaPhieuSuaChua}>
                <Card className="p-5">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <p className="mono text-lg font-bold text-primary">{vehicle?.BienSo}</p>
                      <p className="text-xs text-muted-foreground">
                        {vehicle?.HangXe} {vehicle?.DongXe} · Phiếu {repair.MaPhieuSuaChua} · Hoàn tất {repair.NgayHoanThanh?.slice(0, 10)}
                      </p>
                    </div>
                    <Badge variant="completed" label="Hoàn tất" />
                  </div>
                  {repair.KetQua && <p className="mt-2 text-[13px] text-slate-600">Kết quả: {repair.KetQua}</p>}
                  <div className="mt-3 flex items-center justify-between rounded-lg bg-surface-subtle px-3 py-2.5">
                    <span className="text-xs text-muted-foreground">Tổng chi phí</span>
                    <span className="mono text-sm font-bold text-foreground">{formatCurrency(quotation?.TongTien ?? 0)}</span>
                  </div>
                  <button
                    type="button"
                    onClick={() => setExpanded(open ? null : repair.MaPhieuSuaChua)}
                    aria-expanded={open}
                    className="mt-2 min-h-10 text-sm font-medium text-primary hover:underline"
                  >
                    {open ? "Thu gọn chi tiết" : "Xem chi tiết hạng mục"}
                  </button>
                  {open && (
                    <ul className="mt-2 space-y-2">
                      {lines.map((line) => (
                        <li key={line.MaChiTietBaoGia} className="flex justify-between gap-3 rounded-lg bg-surface-subtle p-3 text-sm">
                          <span className="text-slate-700">{line.NoiDung} <span className="text-muted-foreground">x{line.SoLuong}</span></span>
                          <span className="mono font-semibold">{formatCurrency(line.SoLuong * line.DonGia)}</span>
                        </li>
                      ))}
                    </ul>
                  )}
                </Card>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
