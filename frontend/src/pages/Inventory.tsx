// TV3-TUAN8
import { useState } from "react";
import ChecksTab from "../features/warehouse/ChecksTab";
import ImportsTab from "../features/warehouse/ImportsTab";
import IssuesTab from "../features/warehouse/IssuesTab";
import MovementsTab from "../features/warehouse/MovementsTab";
import StockTab from "../features/warehouse/StockTab";
import { Tabs } from "../components/ui";

const TABS = [
  { key: "stock", label: "Tồn kho" },
  { key: "import", label: "Nhập kho" },
  { key: "export", label: "Xuất kho" },
  { key: "audit", label: "Kiểm kê" },
  { key: "history", label: "Biến động kho" },
];

/** Quản lý kho phụ tùng: dữ liệu lấy từ Spring Boot API (SQL Server), không dùng mock. */
export default function Inventory() {
  const [tab, setTab] = useState("stock");
  // Tăng giá trị này sau mỗi thao tác làm thay đổi tồn để các tab khác tải lại.
  const [refreshKey, setRefreshKey] = useState(0);
  const changed = () => setRefreshKey((key) => key + 1);

  return (
    <div className="space-y-6">
      <div className="page-toolbar">
        <Tabs tabs={TABS} active={tab} onChange={setTab} />
      </div>

      {tab === "stock" && <StockTab refreshKey={refreshKey} />}
      {tab === "import" && <ImportsTab refreshKey={refreshKey} onChanged={changed} />}
      {tab === "export" && <IssuesTab refreshKey={refreshKey} onChanged={changed} />}
      {tab === "audit" && <ChecksTab refreshKey={refreshKey} onChanged={changed} />}
      {tab === "history" && <MovementsTab refreshKey={refreshKey} />}
    </div>
  );
}
