import React, { useState } from "react";
import { Card, Badge, Button, SearchBox, Icons } from "../components/ui";
import { mockVehicles, mockRepairOrders } from "../data";

export default function Vehicles() {
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState<string | null>(null);

  const filtered = mockVehicles.filter(v =>
    !search || v.plate.includes(search) || v.owner.toLowerCase().includes(search.toLowerCase()) || v.brand.toLowerCase().includes(search.toLowerCase())
  );
  const detail = mockVehicles.find(v => v.id === selected);

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between">
        <SearchBox value={search} onChange={setSearch} placeholder="Biển số, chủ xe, hãng xe..." />
        <Button icon={Icons.plus}>Thêm xe</Button>
      </div>

      <div className={`grid gap-4 ${selected ? "grid-cols-3" : "grid-cols-1"}`}>
        <div className={selected ? "col-span-2" : ""}>
          <Card>
            <table className="w-full data-table">
              <thead>
                <tr>
                  <th>Biển số</th>
                  <th>Chủ xe</th>
                  <th>Hãng xe</th>
                  <th>Dòng xe</th>
                  <th className="text-right">Năm SX</th>
                  <th className="text-right">Số km</th>
                  <th>Bảo dưỡng tiếp</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(v => {
                  const serviceDate = new Date(v.nextService);
                  const today = new Date("2024-09-17");
                  const daysLeft = Math.ceil((serviceDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
                  const urgent = daysLeft <= 30;
                  return (
                    <tr key={v.id} className={`cursor-pointer ${selected === v.id ? "bg-blue-50" : ""}`}
                      onClick={() => setSelected(v.id === selected ? null : v.id)}>
                      <td><span className="mono font-bold text-[#1e3a6e]">{v.plate}</span></td>
                      <td className="font-medium text-slate-800">{v.owner}</td>
                      <td className="text-slate-600">{v.brand}</td>
                      <td className="text-slate-600">{v.model}</td>
                      <td className="text-right text-slate-600">{v.year}</td>
                      <td className="text-right mono text-sm">{v.km.toLocaleString("vi-VN")}</td>
                      <td>
                        <span className={`text-xs font-medium ${urgent ? "text-amber-600" : "text-slate-500"}`}>
                          {v.nextService.split("-").reverse().join("/")}
                          {urgent && ` (${daysLeft} ngày)`}
                        </span>
                      </td>
                      <td>
                        <div className="flex gap-1">
                          <button className="p-1.5 hover:bg-slate-100 rounded text-slate-500">{Icons.eye}</button>
                          <button className="p-1.5 hover:bg-slate-100 rounded text-slate-500">{Icons.edit}</button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </Card>
        </div>

        {detail && (
          <div className="space-y-4">
            <Card className="p-5">
              <div className="flex items-start justify-between mb-4">
                <div>
                  <p className="mono text-2xl font-black text-[#1e3a6e]">{detail.plate}</p>
                  <p className="text-slate-600 font-medium">{detail.brand} {detail.model} {detail.year}</p>
                  <p className="text-xs text-slate-400 mt-1 mono">{detail.vin}</p>
                </div>
                <button onClick={() => setSelected(null)} className="p-1 hover:bg-slate-100 rounded text-slate-400">✕</button>
              </div>
              <div className="grid grid-cols-2 gap-3 text-sm">
                <div className="p-3 bg-slate-50 rounded-lg"><p className="text-xs text-slate-400">Chủ xe</p><p className="font-semibold">{detail.owner}</p></div>
                <div className="p-3 bg-slate-50 rounded-lg"><p className="text-xs text-slate-400">Màu sắc</p><p className="font-semibold">{detail.color}</p></div>
                <div className="p-3 bg-slate-50 rounded-lg"><p className="text-xs text-slate-400">Số km</p><p className="font-semibold mono">{detail.km.toLocaleString("vi-VN")} km</p></div>
                <div className="p-3 bg-slate-50 rounded-lg">
                  <p className="text-xs text-slate-400">Bảo dưỡng tiếp</p>
                  <p className="font-semibold text-amber-600">{detail.nextService.split("-").reverse().join("/")}</p>
                </div>
              </div>
            </Card>

            <Card className="p-5">
              <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Lịch sử sửa chữa</p>
              <div className="space-y-2">
                {mockRepairOrders.filter(r => r.vehicle === detail.plate).map(r => (
                  <div key={r.id} className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
                    <div>
                      <p className="mono text-xs text-slate-500">{r.id}</p>
                      <p className="text-xs font-medium text-slate-700">{r.created.split("-").reverse().join("/")}</p>
                    </div>
                    <Badge variant={r.status as any} />
                  </div>
                ))}
                {mockRepairOrders.filter(r => r.vehicle === detail.plate).length === 0 && (
                  <p className="text-xs text-slate-400 text-center py-4">Chưa có lịch sử</p>
                )}
              </div>
            </Card>
          </div>
        )}
      </div>
    </div>
  );
}
