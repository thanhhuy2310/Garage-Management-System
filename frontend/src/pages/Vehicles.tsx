import { useState } from "react";
import { Badge, Button, Card, Icons, Input, Modal, SearchBox, Select, TableContainer } from "../components/ui";
import { khachHang, mockRepairOrders, xe } from "../mock/data";

const customerName = (customerId: string) =>
  khachHang.find((customer) => customer.MaKhachHang === customerId)?.HoTen ?? "Không xác định";

export default function Vehicles() {
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState<string | null>(null);
  const [showAdd, setShowAdd] = useState(false);

  const keyword = search.trim().toLowerCase();
  const filtered = xe.filter((vehicle) => {
    const owner = customerName(vehicle.MaKhachHang).toLowerCase();
    return !keyword
      || vehicle.BienSo.toLowerCase().includes(keyword)
      || owner.includes(keyword)
      || vehicle.HangXe?.toLowerCase().includes(keyword);
  });
  const detail = xe.find((vehicle) => vehicle.MaXe === selected);

  return (
    <div className="space-y-6">
      <div className="page-toolbar">
        <SearchBox value={search} onChange={setSearch} placeholder="Biển số, chủ xe, hãng xe..." />
        <Button icon={Icons.plus} onClick={() => setShowAdd(true)}>Thêm xe</Button>
      </div>

      <div className={`grid gap-4 ${selected ? "xl:grid-cols-3" : "grid-cols-1"}`}>
        <div className={selected ? "xl:col-span-2" : ""}>
          <Card>
            <TableContainer>
            <table className="data-table w-full min-w-[760px]">
              <thead>
                <tr>
                  <th>Mã xe</th>
                  <th>Biển số</th>
                  <th>Chủ xe</th>
                  <th>Hãng xe</th>
                  <th>Dòng xe</th>
                  <th className="text-right">Năm SX</th>
                  <th className="text-right">Số km</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((vehicle) => (
                  <tr
                    key={vehicle.MaXe}
                    tabIndex={0}
                    aria-selected={selected === vehicle.MaXe}
                    onClick={() => setSelected(vehicle.MaXe === selected ? null : vehicle.MaXe)}
                    onKeyDown={(event) => {
                      if (event.currentTarget !== event.target || (event.key !== "Enter" && event.key !== " ")) return;
                      event.preventDefault();
                      setSelected(vehicle.MaXe === selected ? null : vehicle.MaXe);
                    }}
                    className={`cursor-pointer ${selected === vehicle.MaXe ? "bg-info-soft" : ""}`}
                  >
                    <td><span className="mono text-xs text-slate-400">{vehicle.MaXe}</span></td>
                    <td><span className="mono font-bold text-primary">{vehicle.BienSo}</span></td>
                    <td className="font-medium text-slate-800">{customerName(vehicle.MaKhachHang)}</td>
                    <td className="text-slate-600">{vehicle.HangXe || "—"}</td>
                    <td className="text-slate-600">{vehicle.DongXe || "—"}</td>
                    <td className="text-right text-slate-600">{vehicle.NamSanXuat || "—"}</td>
                    <td className="mono text-right text-sm">{vehicle.SoKm?.toLocaleString("vi-VN") ?? "—"}</td>
                    <td>
                      <div className="flex gap-1">
                        <button type="button" aria-label={`Xem xe ${vehicle.BienSo}`} className="flex h-11 w-11 items-center justify-center rounded text-slate-500 hover:bg-slate-100">{Icons.eye}</button>
                        <button type="button" aria-label={`Sửa xe ${vehicle.BienSo}`} className="flex h-11 w-11 items-center justify-center rounded text-slate-500 hover:bg-slate-100">{Icons.edit}</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            </TableContainer>
            {filtered.length === 0 && <p className="py-10 text-center text-sm text-slate-400">Không tìm thấy xe phù hợp.</p>}
          </Card>
        </div>

        {detail && (
          <div className="detail-panel space-y-4">
            <Card className="p-4 sm:p-5">
              <div className="mb-4 flex items-start justify-between">
                <div>
                  <p className="mono text-2xl font-bold text-primary">{detail.BienSo}</p>
                  <p className="font-medium text-slate-600">{detail.HangXe} {detail.DongXe} {detail.NamSanXuat}</p>
                  <p className="mono mt-1 text-xs text-slate-400">{detail.MaXe}</p>
                </div>
                <button type="button" onClick={() => setSelected(null)} aria-label="Đóng chi tiết xe" className="flex h-11 w-11 items-center justify-center rounded text-slate-500 hover:bg-slate-100">✕</button>
              </div>
              <div className="grid grid-cols-2 gap-3 text-sm">
                <div className="rounded-lg bg-slate-50 p-3"><p className="text-xs text-slate-400">Chủ xe</p><p className="font-semibold">{customerName(detail.MaKhachHang)}</p></div>
                <div className="rounded-lg bg-slate-50 p-3"><p className="text-xs text-slate-400">Mã khách hàng</p><p className="mono font-semibold">{detail.MaKhachHang}</p></div>
                <div className="rounded-lg bg-slate-50 p-3"><p className="text-xs text-slate-400">Số km</p><p className="mono font-semibold">{detail.SoKm?.toLocaleString("vi-VN") ?? "—"} km</p></div>
                <div className="rounded-lg bg-slate-50 p-3"><p className="text-xs text-slate-400">Năm sản xuất</p><p className="font-semibold">{detail.NamSanXuat ?? "—"}</p></div>
              </div>
            </Card>

            <Card className="p-4 sm:p-5">
              <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-slate-500">Lịch sử sửa chữa</p>
              <div className="space-y-2">
                {mockRepairOrders.filter((repair) => repair.vehicle === detail.BienSo).map((repair) => (
                  <div key={repair.id} className="flex items-center justify-between rounded-lg bg-slate-50 p-3">
                    <div><p className="mono text-xs text-slate-500">{repair.id}</p><p className="text-xs font-medium text-slate-700">{repair.created.split("-").reverse().join("/")}</p></div>
                    <Badge variant={repair.status as any} />
                  </div>
                ))}
                {mockRepairOrders.filter((repair) => repair.vehicle === detail.BienSo).length === 0 && (
                  <p className="py-4 text-center text-xs text-slate-400">Chưa có lịch sử</p>
                )}
              </div>
            </Card>
          </div>
        )}
      </div>

      <Modal open={showAdd} onClose={() => setShowAdd(false)} title="Thêm xe">
        <div className="space-y-4">
          <Select label="Khách hàng *" options={khachHang.map((customer) => ({ value: customer.MaKhachHang, label: `${customer.HoTen} – ${customer.SoDienThoai}` }))} />
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Input label="Biển số *" placeholder="51A-123.45" />
            <Input label="Hãng xe" placeholder="Toyota" />
            <Input label="Dòng xe" placeholder="Camry" />
            <Input label="Năm sản xuất" type="number" min="1900" max="2100" />
            <Input label="Số km" type="number" min="0" />
          </div>
          <div className="flex justify-end gap-3 pt-2">
            <Button variant="outline" onClick={() => setShowAdd(false)}>Hủy</Button>
            <Button>Lưu xe</Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
