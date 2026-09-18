import React, { useMemo, useState } from "react";
import { Badge, Button, Card, Input, SearchBox, Select, Tabs, Icons } from "../components/ui";
import { formatCurrency } from "../data";
import { bienDongKho, chiTietPhieuNhap, chiTietPhieuXuat, getInventoryStatus, kho, nhanVien, phieuNhapKho, phieuXuatKho, phuTung } from "../mock/schemaData";

const TABS = [
  { key: "stock", label: "Tồn kho" }, { key: "import", label: "Nhập kho" },
  { key: "export", label: "Xuất kho" }, { key: "audit", label: "Kiểm kê" },
  { key: "history", label: "Biến động kho" },
];
const dateTime = (value: string | null) => value ? new Date(value).toLocaleString("vi-VN") : "—";
const employeeName = (id: string | null) => nhanVien.find((x) => x.MaNhanVien === id)?.HoTen ?? "—";
const partName = (id: string) => phuTung.find((x) => x.MaPhuTung === id)?.TenPhuTung ?? id;

export default function Inventory() {
  const [tab, setTab] = useState("stock");
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [confirmed, setConfirmed] = useState<string[]>([]);
  const filtered = useMemo(() => phuTung.filter((item) => {
    const matches = !search || `${item.MaPhuTung} ${item.TenPhuTung}`.toLowerCase().includes(search.toLowerCase());
    return matches && (statusFilter === "all" || getInventoryStatus(item) === statusFilter);
  }), [search, statusFilter]);
  const lowStock = phuTung.filter((item) => getInventoryStatus(item) !== "ok");
  const auditItems = phuTung.map((item, index) => ({ ...item, actual: index === 2 ? item.SoLuongTon - 1 : item.SoLuongTon }));

  return <div className="p-6 space-y-5">
    <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
      <Tabs tabs={TABS} active={tab} onChange={setTab} />
      <p className="text-xs text-slate-500">{kho[0].TenKho} · {kho[0].DiaChi}</p>
    </div>

    {tab === "stock" && <>
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end">
        <SearchBox value={search} onChange={setSearch} placeholder="Mã, tên phụ tùng..." />
        <Select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} options={[{ value: "all", label: "Tất cả trạng thái" }, { value: "ok", label: "Còn hàng" }, { value: "low", label: "Sắp hết" }, { value: "out", label: "Hết hàng" }]} />
      </div>
      <div className="p-4 bg-amber-50 border border-amber-200 rounded-xl flex items-center gap-3 text-sm text-amber-800"><span>{Icons.alertTriangle}</span><span><strong>{lowStock.length} mặt hàng</strong> đang dưới mức tồn tối thiểu.</span></div>
      <Card><table className="w-full data-table">
        <thead><tr><th>Mã phụ tùng</th><th>Tên phụ tùng</th><th>Kho</th><th>Hãng sản xuất</th><th className="text-right">Đơn giá</th><th className="text-right">Số lượng tồn</th><th className="text-right">Mức tối thiểu</th><th>Trạng thái (dẫn xuất)</th></tr></thead>
        <tbody>{filtered.map((item) => { const status = getInventoryStatus(item); return <tr key={item.MaPhuTung}><td className="mono text-xs">{item.MaPhuTung}</td><td className="font-medium">{item.TenPhuTung}</td><td className="mono text-xs">{item.MaKho}</td><td>{item.HangSanXuat ?? "—"}</td><td className="text-right">{formatCurrency(item.DonGia)}</td><td className="text-right font-bold">{item.SoLuongTon}</td><td className="text-right">{item.MucTonToiThieu}</td><td><Badge variant={status} /></td></tr>; })}</tbody>
      </table></Card>
    </>}

    {tab === "import" && <div className="space-y-4">
      <Card className="p-5"><h3 className="font-semibold mb-4">Lập phiếu nhập kho</h3><div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3"><Input label="Ngày nhập *" type="datetime-local" defaultValue="2026-09-18T08:00" /><Input label="Nhà cung cấp *" placeholder="Nhập tên nhà cung cấp" /><Select label="Nhân viên kho *" options={nhanVien.filter((x) => x.ChucVu === "Nhân viên kho").map((x) => ({ value: x.MaNhanVien, label: `${x.MaNhanVien} · ${x.HoTen}` }))} /></div><Input label="Ghi chú" placeholder="Ghi chú phiếu nhập" className="mt-3" /><p className="text-xs text-slate-500 mt-3">Mã phiếu và thành tiền do hệ thống sinh/tính. Thêm chi tiết sẽ tăng tồn qua sp_ThemChiTietPhieuNhap.</p></Card>
      {phieuNhapKho.map((receipt) => { const details = chiTietPhieuNhap.filter((x) => x.MaPhieuNhap === receipt.MaPhieuNhap); return <Card key={receipt.MaPhieuNhap} className="p-5"><div className="flex justify-between mb-4"><div><p className="font-semibold">{receipt.MaPhieuNhap}</p><p className="text-xs text-slate-500">{dateTime(receipt.NgayNhap)} · {receipt.NhaCungCap}</p></div><p className="text-sm">Nhân viên: {employeeName(receipt.MaNhanVienKho)}</p></div><table className="w-full data-table"><thead><tr><th>Mã phụ tùng</th><th>Tên phụ tùng</th><th className="text-right">Số lượng</th><th className="text-right">Đơn giá nhập</th><th className="text-right">Thành tiền (tự tính)</th></tr></thead><tbody>{details.map((d) => <tr key={d.MaPhuTung}><td className="mono text-xs">{d.MaPhuTung}</td><td>{partName(d.MaPhuTung)}</td><td className="text-right">{d.SoLuong}</td><td className="text-right">{formatCurrency(d.DonGiaNhap)}</td><td className="text-right font-semibold">{formatCurrency(d.ThanhTien)}</td></tr>)}</tbody></table>{receipt.GhiChu && <p className="text-xs text-slate-500 mt-3">Ghi chú: {receipt.GhiChu}</p>}</Card>; })}
    </div>}

    {tab === "export" && <div className="space-y-4">
      <div className="p-4 bg-blue-50 border border-blue-200 rounded-xl text-sm text-blue-800">Lập phiếu xuất <strong>chưa trừ tồn kho</strong>. Tồn chỉ giảm khi kỹ thuật viên xác nhận đã sử dụng qua sp_XacNhanSuDungPhuTung.</div>
      <Card className="p-5"><h3 className="font-semibold mb-4">Lập phiếu xuất kho</h3><div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3"><Select label="Phiếu sửa chữa" options={[{ value: "PSC001", label: "PSC001" }, { value: "PSC002", label: "PSC002" }]} /><Select label="Nhân viên kho *" options={[{ value: "NV007", label: "NV007 · Đỗ Văn Nam" }]} /><Select label="Kỹ thuật viên yêu cầu" options={[{ value: "NV002", label: "NV002 · Trần Văn Khoa" }, { value: "NV003", label: "NV003 · Nguyễn Thành Long" }]} /></div><Input label="Lý do *" placeholder="Lý do xuất kho" className="mt-3" /></Card>
      {phieuXuatKho.map((issue) => { const details = chiTietPhieuXuat.filter((x) => x.MaPhieuXuat === issue.MaPhieuXuat); return <Card key={issue.MaPhieuXuat} className="p-5"><div className="flex justify-between mb-3"><div><p className="font-semibold">{issue.MaPhieuXuat} · {issue.MaPhieuSuaChua ?? "Không gắn phiếu sửa chữa"}</p><p className="text-xs text-slate-500">{dateTime(issue.NgayXuat)} · {issue.LyDo}</p></div><p className="text-xs text-slate-500">Kho: {employeeName(issue.MaNhanVienKho)} · Yêu cầu: {employeeName(issue.MaKyThuatVienYeuCau)}</p></div><table className="w-full data-table"><thead><tr><th>Phụ tùng</th><th className="text-right">Số lượng</th><th className="text-right">Đơn giá</th><th>Trạng thái</th><th>Người/ngày xác nhận</th><th></th></tr></thead><tbody>{details.map((d) => { const key = `${d.MaPhieuXuat}-${d.MaPhuTung}`; const done = d.DaXacNhanSuDung || confirmed.includes(key); return <tr key={key}><td>{d.MaPhuTung} · {partName(d.MaPhuTung)}</td><td className="text-right">{d.SoLuong}</td><td className="text-right">{d.DonGia === null ? "—" : formatCurrency(d.DonGia)}</td><td><Badge variant={done ? "completed" : "pending"} label={done ? "Đã xác nhận sử dụng" : "Chờ KTV xác nhận"} /></td><td className="text-xs">{done ? `${employeeName(d.MaKyThuatVienXacNhan ?? issue.MaKyThuatVienYeuCau)} · ${dateTime(d.NgayXacNhan ?? "2026-09-18T09:00:00")}` : "—"}</td><td>{!done && <Button size="sm" variant="secondary" onClick={() => setConfirmed((items) => [...items, key])}>KTV xác nhận sử dụng</Button>}</td></tr>; })}</tbody></table></Card>; })}
    </div>}

    {tab === "audit" && <Card><div className="p-4 border-b flex justify-between"><div><p className="font-semibold">Kiểm kê tồn kho</p><p className="text-xs text-slate-500">Chênh lệch được ghi nhận bằng biến động KIEM_KE qua sp_KiemKeTonKho.</p></div><Button>Lưu kết quả kiểm kê</Button></div><table className="w-full data-table"><thead><tr><th>Mã phụ tùng</th><th>Tên phụ tùng</th><th className="text-right">Tồn hệ thống</th><th className="text-right">Tồn thực tế</th><th className="text-right">Chênh lệch</th><th>Ghi chú</th></tr></thead><tbody>{auditItems.map((item) => { const diff = item.actual - item.SoLuongTon; return <tr key={item.MaPhuTung}><td className="mono text-xs">{item.MaPhuTung}</td><td>{item.TenPhuTung}</td><td className="text-right">{item.SoLuongTon}</td><td className="text-right"><input type="number" defaultValue={item.actual} min={0} className="w-20 border rounded px-2 py-1 text-right" /></td><td className={`text-right font-bold ${diff ? "text-red-600" : "text-emerald-600"}`}>{diff > 0 ? "+" : ""}{diff}</td><td><input placeholder="Ghi chú kiểm kê" className="border rounded px-2 py-1 text-sm" /></td></tr>; })}</tbody></table></Card>}

    {tab === "history" && <Card><table className="w-full data-table"><thead><tr><th>Mã biến động</th><th>Thời gian</th><th>Phụ tùng</th><th>Loại</th><th className="text-right">Số lượng</th><th className="text-right">Trước</th><th className="text-right">Sau</th><th>Chứng từ</th><th>Ghi chú</th></tr></thead><tbody>{bienDongKho.map((m) => <tr key={m.MaBienDong}><td className="mono text-xs">{m.MaBienDong}</td><td>{dateTime(m.ThoiGian)}</td><td>{m.MaPhuTung} · {partName(m.MaPhuTung)}</td><td><Badge variant={m.LoaiBienDong === "NHAP" ? "completed" : m.LoaiBienDong === "XUAT" ? "blue" : "gray"} label={m.LoaiBienDong} /></td><td className="text-right font-semibold">{m.SoLuong > 0 ? "+" : ""}{m.SoLuong}</td><td className="text-right">{m.SoLuongTruoc ?? "—"}</td><td className="text-right">{m.SoLuongSau ?? "—"}</td><td className="mono text-xs">{m.MaPhieuNhap ?? m.MaPhieuXuat ?? "—"}</td><td className="text-xs">{m.GhiChu ?? "—"}</td></tr>)}</tbody></table></Card>}
  </div>;
}
