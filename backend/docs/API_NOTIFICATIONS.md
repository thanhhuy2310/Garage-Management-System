<!-- TV3-TUAN10 -->
# API thông báo và nhắc lịch bảo dưỡng (Tuần 10)

Tài liệu cho TV2 (Trung) viết `ApiNotificationService` thay `MockNotificationService` trên Mobile. **Backend đã có API; Mobile hiện vẫn nối mock cho đến khi Mobile được tích hợp.**

Mọi response dùng cùng envelope `ApiResponse<T>` của project:

```json
{ "success": true, "message": "…", "data": { } }
```

Lỗi: `success = false`, `message` là thông điệp tiếng Việt, `data` là `null` (riêng lỗi 400 do validate `data` là map `tên trường -> thông báo lỗi`).

## 1. Điều kiện chạy (bắt buộc)

1. Đã chạy `QuanLyGaraOTo.sql` rồi các migration `V001`, `V002`, `V003`, **`V004__customer_notifications_and_maintenance_reminders.sql`** (xem `backend/database/migrations/README.md`). Chạy bằng SSMS hoặc `sqlcmd -I` (cần `QUOTED_IDENTIFIER ON`).
2. Không có bảng thông báo mới: dùng lại `ThongBao`. V004 chỉ thêm cột `ThongBao.MaLichNhac`, bảng `LichNhacBaoDuong`, trigger `TRG_LichHen_ThongBao` và mở rộng `TRG_PhieuSuaChua_ThongBaoHoanTat`.

## 2. API dành cho khách hàng

Chỉ role `CUSTOMER`. Backend lấy khách hàng từ tài khoản trong JWT: **không có và không nhận `customerId`** từ query/body (nếu gửi, bị bỏ qua).

| Mã | Khi nào |
|---|---|
| 200 | Thành công |
| 401 | Thiếu/sai/hết hạn token |
| 403 | Không phải `CUSTOMER`, hoặc tài khoản chưa liên kết khách hàng |
| 404 | Thông báo không tồn tại **hoặc không thuộc khách hàng hiện tại** (không phân biệt, không lộ dữ liệu người khác) |

### 2.1. `GET /api/customers/me/notifications`

Danh sách thông báo của khách hàng, **mới nhất trước** (`ThoiGian` giảm dần, rồi `MaThongBao` giảm dần). Có phân trang để không cắt âm thầm:

| Tham số | Mặc định | Ghi chú |
|---|---|---|
| `page` | `0` | Bắt đầu từ 0 |
| `size` | `20` | Tối đa 100 |

```json
{
  "success": true,
  "message": "Lấy danh sách thông báo thành công.",
  "data": {
    "items": [
      {
        "id": 31,
        "title": "Xe đã hoàn tất sửa chữa",
        "message": "Phiếu sửa chữa #12 đã hoàn tất. Vui lòng liên hệ gara để nhận xe.",
        "createdAt": "2026-10-20T09:15:00",
        "type": "repair",
        "isRead": false,
        "appointmentId": null,
        "repairOrderId": 12,
        "maintenanceScheduleId": null
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 41,
    "totalPages": 3
  }
}
```

- `createdAt`: giờ địa phương (Asia/Ho_Chi_Minh), ISO-8601 **không** kèm múi giờ.
- `id`: số nguyên 64 bit (`Long`).
- Còn trang tiếp theo khi `page + 1 < totalPages`. Mobile nên tải trang kế tiếp theo kiểu "Tải thêm"; `totalElements` luôn là tổng đầy đủ.

### 2.2. `GET /api/customers/me/notifications/unread-count`

```json
{ "success": true, "message": "Lấy số thông báo chưa đọc thành công.", "data": { "count": 5 } }
```

Số chưa đọc = số thông báo của khách hàng có `ThongBao.DaDoc = 0`, tính trên toàn bộ (không phụ thuộc trang đang xem). Backend không đẩy thông báo (push): Mobile cập nhật bằng cách gọi lại endpoint này (ví dụ khi mở app, khi vào màn thông báo, hoặc theo chu kỳ).

### 2.3. `PATCH /api/customers/me/notifications/{notificationId}/read`

Đánh dấu một thông báo đã đọc. Kiểm tra **cả mã thông báo lẫn khách hàng** ngay trong câu `UPDATE` ở SQL Server. Idempotent: gọi lại trên thông báo đã đọc vẫn 200.

```json
{
  "success": true,
  "message": "Đã đánh dấu thông báo là đã đọc.",
  "data": {
    "id": 31, "title": "Xe đã hoàn tất sửa chữa", "message": "…", "createdAt": "2026-10-20T09:15:00",
    "type": "repair", "isRead": true, "appointmentId": null, "repairOrderId": 12, "maintenanceScheduleId": null
  }
}
```

Không tồn tại hoặc của người khác:

```json
{ "success": false, "message": "Không tìm thấy thông báo.", "data": null }
```

### 2.4. `PATCH /api/customers/me/notifications/read-all`

Đánh dấu **tất cả** thông báo chưa đọc của khách hàng đăng nhập là đã đọc (không đụng tới khách hàng khác). Không có body.

```json
{
  "success": true,
  "message": "Đã đánh dấu tất cả thông báo là đã đọc.",
  "data": { "updatedCount": 4, "unreadCount": 0 }
}
```

`updatedCount`: số thông báo vừa đổi. Sau khi gọi, Mobile nên tải lại danh sách (hoặc đặt `isRead = true` cho các mục đang hiển thị rồi đồng bộ lại `unread-count`).

## 3. Giá trị `type` và cách map từ `ThongBao.LoaiThongBao`

| `LoaiThongBao` (DB) | `type` (API) | Được tạo bởi |
|---|---|---|
| `LICH_HEN` | `appointment` | Trigger `TRG_LichHen_ThongBao` |
| `TIEN_DO_SUA_CHUA` | `repair` | Trigger `TRG_PhieuSuaChua_ThongBaoHoanTat` (mở rộng) |
| `HOAN_TAT_SUA_CHUA` | `repair` | Trigger `TRG_PhieuSuaChua_ThongBaoHoanTat` (logic gốc) |
| `NHAC_BAO_DUONG` | `maintenance` | `MaintenanceReminderService` (scheduler) |
| giá trị khác | `general` | — |

Các liên kết: `appointmentId` ← `MaLichHen`, `repairOrderId` ← `MaPhieuSuaChua`, `maintenanceScheduleId` ← `MaLichNhac` (null nếu không áp dụng). Chưa có thông báo phụ tùng/thanh toán vì hệ thống chưa phát sinh sự kiện đó.

## 4. Thông báo được tạo khi nào

Thông báo chỉ **ghi nhận** sự kiện nghiệp vụ đã xảy ra; tạo thông báo không đổi trạng thái lịch hẹn, phiếu sửa chữa, báo giá, tồn kho, lịch sử hay hóa đơn.

### 4.1. Lịch hẹn (`LichHen`, trigger `TRG_LichHen_ThongBao`)

Xử lý nhiều dòng (set-based), so sánh `inserted` với `deleted`. Mỗi dòng mỗi lần cập nhật tối đa **một** thông báo, ưu tiên: hủy > đổi ngày/giờ > xác nhận.

| Sự kiện | Tiêu đề |
|---|---|
| Lịch hẹn mới (không phải đã hủy) | `Da ghi nhan lich hen` |
| `TrangThai` đổi sang `DA_XAC_NHAN` | `Lich hen da duoc xac nhan` |
| `NgayHen` hoặc `GioHen` đổi | `Lich hen da doi thoi gian` |
| `TrangThai` đổi sang trạng thái hủy (chứa `HUY`, ví dụ `DA_HUY`) | `Lich hen da bi huy` |

Cập nhật không đổi trạng thái/ngày/giờ (ví dụ chỉ sửa ghi chú) **không** sinh thông báo. Dữ liệu mẫu nạp trước khi trigger tồn tại nên không bị biến thành thông báo mới. Nội dung do SQL tạo là tiếng Việt không dấu (cùng quy ước với trigger gốc).

### 4.2. Tiến độ sửa chữa (`PhieuSuaChua.TrangThai`)

Dùng **cùng một trigger** `TRG_PhieuSuaChua_ThongBaoHoanTat` (không có trigger thứ hai):
- Chuyển sang `HOAN_TAT`: đúng một thông báo `HOAN_TAT_SUA_CHUA` (logic và kiểm tra chống trùng của bản gốc được giữ nguyên; hoàn tất lần nữa cũng không tạo thêm).
- `TrangThai` thật sự đổi sang trạng thái khác `HOAN_TAT` (ví dụ `DANG_SUA`, `CHO_PHU_TUNG`): một thông báo `TIEN_DO_SUA_CHUA`. Cập nhật cùng trạng thái không sinh thông báo; tạo mới phiếu không sinh thông báo tiến độ.
- Khách hàng nhận thông báo là chủ xe của phiếu (qua `PhieuTiepNhan` → `Xe`).

### 4.3. Nhắc bảo dưỡng đến hạn

Dữ liệu đến hạn do nhân viên khai báo ở `LichNhacBaoDuong` (**hệ thống không tự suy ra chu kỳ**, không có mặc định 5.000 km hay 6 tháng). Một lịch nhắc có ngày đến hạn (`NgayDenHan`) và/hoặc số km đến hạn (`SoKmDenHan`).

Scheduler (`MaintenanceReminderScheduler`) chạy hằng ngày và gọi `MaintenanceReminderService.processDue()`:
- Lịch `CHO_NHAC` có `NgayDenHan <= hôm nay` (đến hạn hoặc quá hạn) → nhắc.
- Lịch có `SoKmDenHan` chỉ nhắc khi `Xe.SoKm` **không NULL** và `>= SoKmDenHan`.
- Đặt cả ngày và km: nhắc khi một trong hai đạt.
- Lịch `DA_NHAC` / `DA_HUY` không bao giờ được nhắc lại.
- Cấu hình: `app.reminders.enabled` (mặc định `true`), `app.reminders.cron` (mặc định `0 0 7 * * *`, tức 07:00 hằng ngày), múi giờ cố định `Asia/Ho_Chi_Minh`.

**Chống trùng:** (1) mỗi lịch được "giành quyền" bằng `UPDATE … SET TrangThai='DA_NHAC' WHERE TrangThai='CHO_NHAC'` — chỉ một lượt thắng, kể cả khi hai lượt chạy song song; (2) trạng thái `DA_NHAC` làm job chạy lại hoặc ứng dụng khởi động lại không chọn lại; (3) chỉ mục duy nhất `UX_ThongBao_LichNhac` trên `ThongBao.MaLichNhac`. Trạng thái và thông báo cùng một transaction.

## 5. API cho nhân viên: thiết lập/hủy lịch nhắc bảo dưỡng

Role `ADMIN`, `MANAGER`, `RECEPTIONIST` (khách hàng không có quyền; 403).

### `POST /api/maintenance-reminders` → 201

```json
{ "vehicleId": 3, "serviceId": 2, "dueDate": "2026-11-01", "dueKm": 15000, "note": "Thay dầu và kiểm tra phanh" }
```

- Bắt buộc `vehicleId` và **ít nhất một** trong `dueDate`, `dueKm`. `dueKm >= 0`. `serviceId` tùy chọn nhưng nếu có phải là dịch vụ loại `BAO_DUONG`.
- 400: thiếu cả ngày và km, km âm, dịch vụ không phải bảo dưỡng. 404: xe/dịch vụ không tồn tại.
- Response `data`: `id`, `vehicleId`, `serviceId`, `dueDate`, `dueKm`, `note`, `status` (`CHO_NHAC`), `createdAt`, `remindedAt` (null).

### `GET /api/maintenance-reminders?vehicleId=&status=&page=0&size=20`

`status` ∈ `CHO_NHAC`, `DA_NHAC`, `DA_HUY` (bỏ trống hoặc `ALL` = tất cả). Trả `items`, `page`, `size`, `totalElements`, `totalPages`.

### `POST /api/maintenance-reminders/{id}/cancel`

Hủy lịch chưa nhắc → `status = DA_HUY`. Hủy lại lịch đã hủy: 200 (idempotent). Lịch đã nhắc: 409. Không tồn tại: 404.

## 6. Việc cần biết khi nối Flutter

- Thay `MockNotificationService` bằng service gọi `GET /api/customers/me/notifications` (dùng `items`, tải thêm theo `page`/`totalPages`) và các endpoint ở mục 2; `type` map: `appointment`, `repair`, `maintenance`, `general`.
- Trường đọc/chưa đọc có tên JSON **`isRead`** (không phải `read`).
- Đọc/đánh dấu đã đọc phải gọi API (trạng thái nằm ở SQL Server), không lưu cục bộ.
- Mobile không tạo thông báo; chỉ đọc. Không gửi `customerId`.
