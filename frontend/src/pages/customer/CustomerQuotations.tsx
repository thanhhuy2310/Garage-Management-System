import { useMemo, useState } from "react";
import { Badge, Button, Card, Icons } from "../../components/ui";
import { baoGia, chiTietBaoGia, formatCurrency, phieuSuaChua, phieuTiepNhan, xe, type QuotationStatus } from "../../mock/data";

const CUSTOMER_ID = "KH001";

const STATUS_VARIANT: Record<QuotationStatus, "pending" | "confirmed" | "rejected" | "draft"> = {
  pending: "pending",
  confirmed: "confirmed",
  rejected: "rejected",
  draft: "draft",
};

const STATUS_LABEL: Record<QuotationStatus, string> = {
  pending: "Chờ xác nhận",
  confirmed: "Đã xác nhận",
  rejected: "Từ chối",
  draft: "Nháp",
};

function repairCustomerId(repairId: string): string | null {
  const repair = phieuSuaChua.find((r) => r.MaPhieuSuaChua === repairId);
  const reception = phieuTiepNhan.find((t) => t.MaTiepNhan === repair?.MaTiepNhan);
  return xe.find((v) => v.MaXe === reception?.MaXe)?.MaKhachHang ?? null;
}

export default function CustomerQuotations() {
  const [selected, setSelected] = useState<string | null>(null);
  const [confirmedIds, setConfirmedIds] = useState<string[]>([]);

  const myQuotations = useMemo(
    () => baoGia.filter((q) => repairCustomerId(q.MaPhieuSuaChua) === CUSTOMER_ID),
    [],
  );
  const detail = myQuotations.find((q) => q.MaBaoGia === selected);
  const detailLines = useMemo(
    () => chiTietBaoGia.filter((line) => line.MaBaoGia === selected),
    [selected],
  );

  return (
    <div className="space-y-4">
      <div>
        <h2 className="ui-section-title">Báo giá của tôi</h2>
        <p className="ui-secondary-text text-sm">{myQuotations.length} báo giá · xác nhận trước khi gara sửa chữa</p>
      </div>

      {myQuotations.length === 0 ? (
        <Card className="p-10 text-center">
          <p className="ui-card-title">Chưa có báo giá</p>
          <p className="ui-secondary-text mt-1 text-sm">Sau khi kiểm tra xe, gara sẽ gửi báo giá tại đây.</p>
        </Card>
      ) : (
        <div className={`grid gap-4 ${selected ? "xl:grid-cols-3" : "grid-cols-1"}`}>
          <ul className={`grid gap-4 ${selected ? "md:grid-cols-2 xl:col-span-2 xl:grid-cols-1" : "md:grid-cols-2"}`}>
            {myQuotations.map((quotation) => {
              const isConfirmed = quotation.TrangThai === "confirmed" || confirmedIds.includes(quotation.MaBaoGia);
              return (
                <li key={quotation.MaBaoGia}>
                  <Card className="h-full p-5">
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <p className="mono text-sm font-bold text-primary">{quotation.MaBaoGia}</p>
                        <p className="mt-0.5 text-xs text-muted-foreground">
                          Phiếu {quotation.MaPhieuSuaChua} · {quotation.NgayLap.slice(0, 10)}
                        </p>
                      </div>
                      <Badge variant={isConfirmed ? "confirmed" : STATUS_VARIANT[quotation.TrangThai]} label={isConfirmed ? "Đã xác nhận" : STATUS_LABEL[quotation.TrangThai]} />
                    </div>
                    <p className="mono mt-3 text-xl font-bold text-foreground">{formatCurrency(quotation.TongTien)}</p>
                    <div className="mt-3 flex gap-2">
                      <Button size="sm" variant="outline" onClick={() => setSelected(quotation.MaBaoGia)}>Xem chi tiết</Button>
                      {!isConfirmed && (
                        <Button size="sm" onClick={() => setConfirmedIds((ids) => [...ids, quotation.MaBaoGia])}>
                          Xác nhận báo giá
                        </Button>
                      )}
                    </div>
                  </Card>
                </li>
              );
            })}
          </ul>

          {detail && (
            <Card className="detail-panel h-fit p-5">
              <div className="mb-3 flex items-start justify-between">
                <div>
                  <p className="mono text-sm font-bold text-primary">{detail.MaBaoGia}</p>
                  <p className="text-xs text-muted-foreground">Chi tiết hạng mục</p>
                </div>
                <button type="button" onClick={() => setSelected(null)} aria-label="Đóng chi tiết" className="flex h-9 w-9 items-center justify-center rounded text-slate-500 hover:bg-slate-100">✕</button>
              </div>
              <ul className="space-y-2">
                {detailLines.map((line) => (
                  <li key={line.MaChiTietBaoGia} className="rounded-lg bg-surface-subtle p-3 text-sm">
                    <p className="font-medium text-slate-800">{line.NoiDung}</p>
                    <p className="mt-1 flex justify-between text-xs text-muted-foreground">
                      <span>x{line.SoLuong} · {formatCurrency(line.DonGia)}</span>
                      <span className="mono font-bold text-foreground">{formatCurrency(line.SoLuong * line.DonGia)}</span>
                    </p>
                  </li>
                ))}
              </ul>
              <div className="mt-3 flex justify-between border-t border-border pt-3">
                <span className="text-sm font-semibold">Tổng cộng</span>
                <span className="mono font-bold text-primary">{formatCurrency(detail.TongTien)}</span>
              </div>
              {detail.TrangThai === "pending" && !confirmedIds.includes(detail.MaBaoGia) && (
                <Button
                  className="mt-4 w-full"
                  icon={Icons.checkCircle}
                  onClick={() => setConfirmedIds((ids) => [...ids, detail.MaBaoGia])}
                >
                  Xác nhận báo giá này
                </Button>
              )}
            </Card>
          )}
        </div>
      )}
    </div>
  );
}
