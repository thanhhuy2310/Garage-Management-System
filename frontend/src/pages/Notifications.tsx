import React, { useState } from "react";
import { Card, Badge, Button, Tabs, Icons } from "../components/ui";
import { mockNotifications } from "../data";

const TYPE_ICON: Record<string, React.ReactNode> = {
  appointment: <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>,
  repair: <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/></svg>,
  parts: <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/></svg>,
  payment: <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>,
};

const TYPE_COLOR: Record<string, string> = {
  appointment: "bg-blue-100 text-blue-600",
  repair: "bg-emerald-100 text-emerald-600",
  parts: "bg-amber-100 text-amber-600",
  payment: "bg-purple-100 text-purple-600",
};

export default function Notifications() {
  const [filter, setFilter] = useState("all");
  const [notifications, setNotifications] = useState(mockNotifications);

  const filtered = notifications.filter(n => {
    if (filter === "unread") return !n.read;
    if (filter === "read") return n.read;
    return true;
  });

  const markAllRead = () => setNotifications(prev => prev.map(n => ({ ...n, read: true })));
  const markRead = (id: string) => setNotifications(prev => prev.map(n => n.id === id ? { ...n, read: true } : n));

  return (
    <div className="p-6 space-y-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <Tabs
          tabs={[
            { key: "all", label: "Tất cả", count: notifications.length },
            { key: "unread", label: "Chưa đọc", count: notifications.filter(n => !n.read).length },
            { key: "read", label: "Đã đọc" },
          ]}
          active={filter}
          onChange={setFilter}
        />
        <Button variant="ghost" size="sm" onClick={markAllRead}>Đánh dấu tất cả đã đọc</Button>
      </div>

      <div className="max-w-3xl space-y-2">
        {filtered.length === 0 && (
          <Card className="py-16 flex items-center justify-center text-slate-400">
            <p className="text-sm">Không có thông báo nào</p>
          </Card>
        )}
        {filtered.map(n => (
          <button key={n.id} type="button"
            className={`flex w-full items-start gap-4 rounded-lg border bg-white p-4 text-left transition-all hover:border-slate-300 ${!n.read ? "border-blue-200 bg-blue-50/50" : "border-border"}`}
            onClick={() => markRead(n.id)} aria-label={`${n.read ? "Thông báo đã đọc" : "Đánh dấu đã đọc"}: ${n.title}`}>
            <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${TYPE_COLOR[n.type]}`}>
              {TYPE_ICON[n.type]}
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-start justify-between gap-2">
                <p className={`font-semibold text-sm ${!n.read ? "text-slate-900" : "text-slate-700"}`}>{n.title}</p>
                {!n.read && <span className="w-2 h-2 bg-blue-500 rounded-full flex-shrink-0 mt-1.5" />}
              </div>
              <p className="text-sm text-slate-600 mt-0.5">{n.body}</p>
              <p className="text-xs text-slate-400 mt-1">
                {new Date(n.time).toLocaleString("vi-VN")} · KH: {n.customerId}
                {n.appointmentId ? ` · Lịch: ${n.appointmentId}` : ""}
                {n.repairId ? ` · Phiếu SC: ${n.repairId}` : ""}
              </p>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}
