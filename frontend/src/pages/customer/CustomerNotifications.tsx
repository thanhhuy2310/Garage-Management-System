import { useCallback, useState } from "react";
import { notificationsApi } from "../../api/notifications";
import { errorMessage } from "../../api/client";
import { QueryState } from "../../components/garage/QueryState";
import { Button, Card, Icons } from "../../components/ui";
import { useGarageQuery } from "../../hooks/useGarageQuery";

const TYPE_META: Record<string, { icon: React.ReactNode; tint: string; label: string }> = {
  appointment: { icon: Icons.calendar, tint: "bg-info-soft text-info", label: "Lịch hẹn" },
  repair: { icon: Icons.wrench, tint: "bg-primary-soft text-primary", label: "Sửa chữa" },
  maintenance: { icon: Icons.car, tint: "bg-warning-soft text-warning", label: "Bảo dưỡng" },
  general: { icon: Icons.info, tint: "bg-muted text-muted-foreground", label: "Thông báo" },
};

export default function CustomerNotifications() {
  const [page, setPage] = useState(0);
  const [busyId, setBusyId] = useState<number | null>(null);
  const [busyAll, setBusyAll] = useState(false);
  const [actionError, setActionError] = useState("");
  const query = useCallback((signal: AbortSignal) => notificationsApi.list(page, signal), [page]);
  const notices = useGarageQuery(query);
  const unread = useGarageQuery(notificationsApi.unreadCount);

  const refresh = () => {
    notices.reload();
    unread.reload();
  };

  const markRead = async (id: number) => {
    setActionError("");
    setBusyId(id);
    try {
      await notificationsApi.markRead(id);
      refresh();
    } catch (error) {
      setActionError(errorMessage(error, "Không đánh dấu được thông báo. Vui lòng thử lại."));
    } finally {
      setBusyId(null);
    }
  };

  const markAllRead = async () => {
    setActionError("");
    setBusyAll(true);
    try {
      await notificationsApi.markAllRead();
      refresh();
    } catch (error) {
      setActionError(errorMessage(error, "Không đánh dấu được thông báo. Vui lòng thử lại."));
    } finally {
      setBusyAll(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="page-toolbar">
        <div>
          <h2 className="ui-section-title">Thông báo</h2>
          <p className="ui-secondary-text text-sm">
            {unread.loading ? "Đang tải số chưa đọc..." : unread.error
              ? "Chưa tải được số chưa đọc"
              : unread.data?.count
                ? `${unread.data.count} chưa đọc`
                : "Đã đọc hết"}
          </p>
        </div>
        {(unread.data?.count ?? 0) > 0 && (
          <Button variant="outline" disabled={busyAll || busyId !== null} onClick={markAllRead}>
            {busyAll ? "Đang cập nhật..." : "Đánh dấu đã đọc hết"}
          </Button>
        )}
      </div>

      {actionError && <p role="alert" className="text-sm text-danger">{actionError}</p>}
      {unread.error && <button type="button" className="text-sm text-primary underline" onClick={unread.reload}>Tải lại số chưa đọc</button>}
      <QueryState loading={notices.loading} error={notices.error} onRetry={notices.reload} />
      {!notices.loading && !notices.error && notices.data?.items.length === 0 && (
        <Card className="p-10 text-center">
          <p className="ui-card-title">Chưa có thông báo</p>
          <p className="ui-secondary-text mt-1 text-sm">Lịch hẹn, tiến độ sửa chữa và nhắc bảo dưỡng sẽ hiện tại đây.</p>
        </Card>
      )}
      {!notices.loading && !notices.error && notices.data && notices.data.items.length > 0 && (
        <>
          <ul className="space-y-3">
            {notices.data.items.map((notice) => {
              const meta = TYPE_META[notice.type] ?? TYPE_META.general;
              return (
                <li key={notice.id}>
                  <button
                    type="button"
                    disabled={notice.isRead || busyId !== null || busyAll}
                    onClick={() => markRead(notice.id)}
                    className={`flex w-full items-start gap-4 rounded-lg border p-4 text-left transition-all hover:border-slate-300 disabled:cursor-default ${notice.isRead ? "border-border bg-white" : "border-info/30 bg-info-soft/40"}`}
                  >
                    <span className={`flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-lg ${meta.tint}`} aria-hidden="true">
                      {meta.icon}
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="flex items-center gap-2">
                        <span className="truncate text-sm font-semibold text-foreground">{notice.title}</span>
                        {!notice.isRead && <span className="h-2 w-2 flex-shrink-0 rounded-full bg-info" aria-label="Chưa đọc" />}
                      </span>
                      <span className="mt-1 block text-sm leading-relaxed text-slate-600">{notice.message}</span>
                      <span className="mt-1 block text-xs text-slate-400">
                        {meta.label} · {notice.createdAt.slice(0, 16).replace("T", " ")}
                      </span>
                    </span>
                  </button>
                </li>
              );
            })}
          </ul>
          {notices.data.totalPages > 1 && (
            <div className="flex items-center justify-end gap-3">
              <Button variant="outline" disabled={page === 0} onClick={() => setPage(page - 1)}>Trước</Button>
              <span className="text-sm text-muted-foreground">Trang {page + 1}/{notices.data.totalPages}</span>
              <Button variant="outline" disabled={page + 1 >= notices.data.totalPages} onClick={() => setPage(page + 1)}>Sau</Button>
            </div>
          )}
        </>
      )}
    </div>
  );
}
