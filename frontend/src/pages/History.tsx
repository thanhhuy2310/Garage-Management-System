import { useCallback, useState } from "react";
import { Card, Button, SearchBox } from "../components/ui";
import { QueryState } from "../components/garage/QueryState";
import { useGarageQuery } from "../hooks/useGarageQuery";
import { garageApi } from "../api/garage";
import { repairDetailsApi } from "../api/repairDetails";
import { formatGarageDate, formatMoney } from "../utils/garageFormat";
function Detail({id}: {id: number}) {
  const load = useCallback(() => repairDetailsApi.list(id), [id]);
  const query = useGarageQuery(load);
  return <Card className="space-y-3 p-5"><QueryState {...query} onRetry={query.reload}/>{query.data && <><h3 className="ui-card-title">Hạng mục phiếu #{id}</h3>{query.data.items.map(line => <div key={`${line.type}-${line.itemId}`} className="flex justify-between gap-3 text-sm"><span>{line.itemName} × {line.quantity}</span><span>{formatMoney(line.lineTotal)}</span></div>)}<p className="border-t pt-3 font-semibold">Tổng chi phí: {formatMoney(query.data.totalAmount)}</p></>}</Card>;
}
export default function History() {
  const query = useGarageQuery(garageApi.repairOrders);
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState<number | null>(null);
  const [from, setFrom] = useState(""); const [to, setTo] = useState("");
  const rows = query.data?.filter(r => r.status === "HOAN_TAT" && `${r.licensePlate} ${r.customerName}`.toLocaleLowerCase("vi").includes(search.toLocaleLowerCase("vi")) && (!from || (r.completedAt ?? "").slice(0,10) >= from) && (!to || (r.completedAt ?? "").slice(0,10) <= to)) ?? [];
  return <div className="space-y-6"><div className="page-toolbar"><SearchBox value={search} onChange={setSearch} placeholder="Biển số, khách hàng..."/><input type="date" aria-label="Từ ngày" value={from} onChange={e => setFrom(e.target.value)}/><input type="date" aria-label="Đến ngày" value={to} onChange={e => setTo(e.target.value)}/></div>
   <QueryState {...query} onRetry={query.reload}/>
   {query.data && rows.length === 0 && <Card className="p-10 text-center">Không có lịch sử phù hợp.</Card>}
   <div className="grid gap-4 xl:grid-cols-2"><div className="space-y-3">{rows.map(r => <Card key={r.id} className="space-y-2 p-5"><p className="mono font-bold text-primary">{r.licensePlate} · Phiếu #{r.id}</p><p>{r.customerName}</p><p className="text-sm text-muted-foreground">Hoàn tất {formatGarageDate(r.completedAt)}</p>{r.result && <p className="text-sm">{r.result}</p>}<Button variant="outline" onClick={() => setSelected(r.id)}>Xem hạng mục #{r.id}</Button></Card>)}</div>{selected && <Detail key={selected} id={selected}/>}</div>
  </div>;
}
