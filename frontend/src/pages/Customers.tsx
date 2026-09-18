import React, { useState } from "react";
import { Card, Badge, Button, SearchBox, Pagination, Icons, Modal, Input } from "../components/ui";
import { mockCustomers, mockVehicles, mockRepairOrders } from "../data";

export default function Customers() {
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [selected, setSelected] = useState<string | null>(null);
  const [showAdd, setShowAdd] = useState(false);
  const PER = 8;

  const filtered = mockCustomers.filter(c =>
    !search || c.name.toLowerCase().includes(search.toLowerCase()) || c.phone.includes(search)
  );
  const paged = filtered.slice((page - 1) * PER, page * PER);
  const detail = mockCustomers.find(c => c.id === selected);

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <SearchBox value={search} onChange={setSearch} placeholder="Tên, số điện thoại..." />
          <Button variant="outline" size="sm" icon={Icons.filter}>Lọc</Button>
        </div>
        <Button icon={Icons.plus} onClick={() => setShowAdd(true)}>Thêm khách hàng</Button>
      </div>

      <div className={`grid gap-4 ${selected ? "grid-cols-3" : "grid-cols-1"}`}>
        {/* Table */}
        <div className={selected ? "col-span-2" : ""}>
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
                {paged.map(c => (
                  <tr key={c.id} className={`cursor-pointer ${selected === c.id ? "bg-blue-50" : ""}`}
                    onClick={() => setSelected(c.id === selected ? null : c.id)}>
                    <td><span className="mono text-xs text-slate-400">{c.id}</span></td>
                    <td>
                      <div className="flex items-center gap-2">
                        <div className="w-7 h-7 bg-gradient-to-br from-blue-400 to-indigo-600 rounded-full flex items-center justify-center text-white text-xs font-bold flex-shrink-0">
                          {c.name.charAt(0)}
                        </div>
                        <span className="font-medium text-slate-800">{c.name}</span>
                      </div>
                    </td>
                    <td><span className="mono text-sm">{c.phone}</span></td>
                    <td className="text-slate-500">{c.email}</td>
                    <td className="text-slate-500 max-w-[160px] truncate">{c.address}</td>
                    <td className="text-center">
                      <span className="inline-flex items-center justify-center w-6 h-6 bg-[#e8eef7] text-[#1e3a6e] text-xs font-bold rounded-full">{c.vehicles}</span>
                    </td>
                    <td>
                      <div className="flex gap-1">
                        <button className="p-1.5 hover:bg-slate-100 rounded text-slate-500">{Icons.eye}</button>
                        <button className="p-1.5 hover:bg-slate-100 rounded text-slate-500">{Icons.edit}</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            <div className="flex items-center justify-between px-4 py-3 border-t border-[#dde3ec]">
              <p className="text-xs text-slate-500">{filtered.length} khách hàng</p>
              <Pagination page={page} total={filtered.length} perPage={PER} onChange={setPage} />
            </div>
          </Card>
        </div>

        {/* Detail panel */}
        {detail && (
          <div className="space-y-4">
            <Card className="p-5">
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 bg-gradient-to-br from-blue-400 to-indigo-600 rounded-xl flex items-center justify-center text-white font-bold text-lg">
                    {detail.name.charAt(0)}
                  </div>
                  <div>
                    <h3 className="font-bold text-slate-800">{detail.name}</h3>
                    <p className="text-xs text-slate-500 mono">{detail.id}</p>
                  </div>
                </div>
                <button onClick={() => setSelected(null)} className="p-1 hover:bg-slate-100 rounded text-slate-400">✕</button>
              </div>
              <div className="space-y-3 text-sm">
                <div className="flex items-center gap-2 text-slate-600">
                  <span className="text-slate-400">{Icons.users}</span>
                  <span className="mono">{detail.phone}</span>
                </div>
                <div className="flex items-center gap-2 text-slate-600">
                  <span className="text-slate-400">{Icons.send}</span>
                  <span>{detail.email}</span>
                </div>
                <div className="flex items-start gap-2 text-slate-600">
                  <span className="text-slate-400 mt-0.5">{Icons.info}</span>
                  <span>{detail.address}</span>
                </div>
                <div className="flex items-center gap-2 text-slate-500">
                  <span className="text-slate-400">{Icons.calendar}</span>
                  <span>Khách từ {detail.joined.split("-").reverse().join("/")}</span>
                </div>
              </div>
            </Card>

            {/* Vehicles */}
            <Card className="p-5">
              <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Xe ({detail.vehicles})</p>
              <div className="space-y-2">
                {mockVehicles.filter(v => v.ownerId === detail.id).map(v => (
                  <div key={v.id} className="flex items-center gap-3 p-3 bg-slate-50 rounded-lg">
                    <span className="text-[#1e3a6e]">{Icons.car}</span>
                    <div>
                      <p className="font-mono font-semibold text-sm text-[#1e3a6e]">{v.plate}</p>
                      <p className="text-xs text-slate-500">{v.brand} {v.model} {v.year}</p>
                    </div>
                  </div>
                ))}
              </div>
            </Card>

            {/* Repair history */}
            <Card className="p-5">
              <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Lịch sử gần đây</p>
              <div className="space-y-2">
                {mockRepairOrders.filter(r => r.customerId === detail.id).map(r => (
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
          <div className="grid grid-cols-2 gap-4">
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
