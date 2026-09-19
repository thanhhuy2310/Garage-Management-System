import React, { useState } from "react";
import { Card, Badge, Button, SearchBox, Pagination, Icons, Modal, Input } from "../components/ui";
import { khachHang, xe, mockRepairOrders } from "../mock/data";

export default function Customers() {
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [selected, setSelected] = useState<string | null>(null);
  const [showAdd, setShowAdd] = useState(false);
  const PER = 8;

  const filtered = khachHang.filter(customer =>
    !search || customer.HoTen.toLowerCase().includes(search.toLowerCase()) || customer.SoDienThoai.includes(search)
  );
  const paged = filtered.slice((page - 1) * PER, page * PER);
  const detail = khachHang.find(customer => customer.MaKhachHang === selected);
  const detailVehicles = xe.filter(vehicle => vehicle.MaKhachHang === detail?.MaKhachHang);

  return (
    <div className="space-y-5">
      <div className="page-toolbar">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
          <SearchBox value={search} onChange={setSearch} placeholder="Tên, số điện thoại..." />
          <Button variant="outline" size="sm" icon={Icons.filter}>Lọc</Button>
        </div>
        <Button icon={Icons.plus} onClick={() => setShowAdd(true)}>Thêm khách hàng</Button>
      </div>

      <div className={`grid gap-4 ${selected ? "xl:grid-cols-3" : "grid-cols-1"}`}>
        {/* Table */}
        <div className={selected ? "xl:col-span-2" : ""}>
          <Card>
            <table className="w-full data-table">
              <thead>
                <tr>
                  <th>Mã KH</th>
                  <th>Họ tên</th>
                  <th>Số điện thoại</th>
                  <th>Email</th>
                  <th>Địa chỉ</th>
                  <th className="text-center">Số xe</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {paged.map(customer => {
                  const vehicleCount = xe.filter(vehicle => vehicle.MaKhachHang === customer.MaKhachHang).length;
                  return (
                  <tr
                    key={customer.MaKhachHang}
                    tabIndex={0}
                    aria-selected={selected === customer.MaKhachHang}
                    className={`cursor-pointer ${selected === customer.MaKhachHang ? "bg-info-soft" : ""}`}
                    onClick={() => setSelected(customer.MaKhachHang === selected ? null : customer.MaKhachHang)}
                    onKeyDown={(event) => {
                      if (event.currentTarget !== event.target || (event.key !== "Enter" && event.key !== " ")) return;
                      event.preventDefault();
                      setSelected(customer.MaKhachHang === selected ? null : customer.MaKhachHang);
                    }}
                  >
                    <td><span className="mono text-xs text-slate-400">{customer.MaKhachHang}</span></td>
                    <td>
                      <div className="flex items-center gap-2">
                        <div className="w-7 h-7 bg-gradient-to-br from-blue-400 to-indigo-600 rounded-full flex items-center justify-center text-white text-xs font-bold flex-shrink-0">
                          {customer.HoTen.charAt(0)}
                        </div>
                        <span className="font-medium text-slate-800">{customer.HoTen}</span>
                      </div>
                    </td>
                    <td><span className="mono text-sm">{customer.SoDienThoai}</span></td>
                    <td className="text-slate-500">{customer.Email || "—"}</td>
                    <td className="text-slate-500 max-w-[160px] truncate">{customer.DiaChi || "—"}</td>
                    <td className="text-center">
                      <span className="inline-flex h-6 w-6 items-center justify-center rounded-full bg-primary-soft text-xs font-bold text-primary">{vehicleCount}</span>
                    </td>
                    <td>
                      <div className="flex gap-1">
                        <button aria-label={`Xem khách hàng ${customer.HoTen}`} className="flex h-9 w-9 items-center justify-center rounded text-slate-500 hover:bg-slate-100">{Icons.eye}</button>
                        <button aria-label={`Sửa khách hàng ${customer.HoTen}`} className="flex h-9 w-9 items-center justify-center rounded text-slate-500 hover:bg-slate-100">{Icons.edit}</button>
                      </div>
                    </td>
                  </tr>
                )})}
              </tbody>
            </table>
            <div className="flex items-center justify-between border-t border-border px-4 py-3">
              <p className="text-xs text-slate-500">{filtered.length} khách hàng</p>
              <Pagination page={page} total={filtered.length} perPage={PER} onChange={setPage} />
            </div>
          </Card>
        </div>

        {/* Detail panel */}
        {detail && (
          <div className="detail-panel space-y-4">
            <Card className="p-5">
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className="flex h-12 w-12 items-center justify-center rounded-full bg-primary text-lg font-bold text-white">
                    {detail.HoTen.charAt(0)}
                  </div>
                  <div>
                    <h3 className="font-bold text-slate-800">{detail.HoTen}</h3>
                    <p className="text-xs text-slate-500 mono">{detail.MaKhachHang}</p>
                  </div>
                </div>
                <button aria-label="Đóng thông tin khách hàng" onClick={() => setSelected(null)} className="flex h-9 w-9 items-center justify-center rounded text-slate-500 hover:bg-slate-100">✕</button>
              </div>
              <div className="space-y-3 text-sm">
                <div className="flex items-center gap-2 text-slate-600">
                  <span className="text-slate-400">{Icons.users}</span>
                  <span className="mono">{detail.SoDienThoai}</span>
                </div>
                <div className="flex items-center gap-2 text-slate-600">
                  <span className="text-slate-400">{Icons.send}</span>
                  <span>{detail.Email || "Chưa cập nhật"}</span>
                </div>
                <div className="flex items-start gap-2 text-slate-600">
                  <span className="text-slate-400 mt-0.5">{Icons.info}</span>
                  <span>{detail.DiaChi || "Chưa cập nhật"}</span>
                </div>
              </div>
            </Card>

            {/* Vehicles */}
            <Card className="p-5">
              <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Xe ({detailVehicles.length})</p>
              <div className="space-y-2">
                {detailVehicles.map(vehicle => (
                  <div key={vehicle.MaXe} className="flex items-center gap-3 p-3 bg-slate-50 rounded-lg">
                    <span className="text-primary">{Icons.car}</span>
                    <div>
                      <p className="mono text-sm font-semibold text-primary">{vehicle.BienSo}</p>
                      <p className="text-xs text-slate-500">{vehicle.HangXe} {vehicle.DongXe} {vehicle.NamSanXuat}</p>
                    </div>
                  </div>
                ))}
              </div>
            </Card>

            {/* Repair history */}
            <Card className="p-5">
              <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Lịch sử gần đây</p>
              <div className="space-y-2">
                {mockRepairOrders.filter(r => r.customerId === detail.MaKhachHang).map(r => (
                  <div key={r.id} className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
                    <div>
                      <p className="mono text-xs text-slate-500">{r.id}</p>
                      <p className="text-xs font-medium">{r.created.split("-").reverse().join("/")}</p>
                    </div>
                    <Badge variant={r.status as any} />
                  </div>
                ))}
              </div>
            </Card>
          </div>
        )}
      </div>

      <Modal open={showAdd} onClose={() => setShowAdd(false)} title="Thêm khách hàng mới">
        <div className="space-y-4">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Input label="Họ và tên *" placeholder="Nguyễn Văn A" />
            <Input label="Số điện thoại *" placeholder="0901234567" />
          </div>
          <Input label="Email" placeholder="email@gmail.com" type="email" />
          <Input label="Địa chỉ" placeholder="Số nhà, đường, quận, TP" />
          <div className="flex gap-3 pt-2 justify-end">
            <Button variant="outline" onClick={() => setShowAdd(false)}>Hủy</Button>
            <Button>Lưu khách hàng</Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
