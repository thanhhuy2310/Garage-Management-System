# Backend

Thư mục này chứa API của hệ thống gara. Backend dùng Java 21, Spring Boot và SQL Server.

## Cách chạy

1. Nếu chưa có database, chạy `database/QuanLyGaraOTo.sql` trong SQL Server Management Studio. Database đang có dữ liệu thì không chạy lại file này.
2. Chọn database `QuanLyGaraOTo`, chạy các file theo thứ tự chính xác trong [`database/migrations/README.md`](database/migrations/README.md). Hai nhánh lịch sử có tên V002/V003 trùng nhau nên không chạy theo thứ tự tên file.
3. Sao chép `.env.example` thành `.env` và điền thông tin kết nối SQL Server.
4. Chạy lệnh:

```powershell
.\run-dev.ps1
```

Cũng có thể chạy class `QuanLyGaraApplication` bằng IntelliJ IDEA.

Để kiểm tra backend, mở:

```text
http://localhost:8080/api/health
```

<!-- TV3-TUAN8-AUDIT:db-setup BEGIN -->
### Cập nhật cấu trúc database (bắt buộc)

Sau khi chạy `QuanLyGaraOTo.sql`, chạy tiếp các migration trong `backend/database/migrations/` **theo thứ tự**:

1. `V001__add_customer_status.sql`
2. `V002__warehouse_actual_used_and_stock_check.sql` — bắt buộc cho kho (Tuần 8): thêm `SoLuongThucDung`, `SoLuongHoanTra`, bảng `PhieuKiemKe`/`ChiTietKiemKe`; sửa `sp_XacNhanSuDungPhuTung` (trừ tồn theo số lượng thực dùng) và `sp_KiemKeTonKho` (chỉ ghi nhận, không tự đổi tồn; chỉ MANAGER duyệt qua ứng dụng).
3. `V003__confirm_usage_row_lock.sql` — khóa dòng khi xác nhận thực dùng, chặn xác nhận trùng đồng thời.

Kiểm thử nghiệp vụ kho (tùy chọn): chạy `backend/database/Test_Warehouse.sql` trong SQL Server Management Studio, xem bảng PASS/FAIL (script tự dọn dữ liệu test).
Chi tiết từng file: `backend/database/migrations/README.md`.

Kho phụ tùng (tồn kho, nhập kho, xuất/cấp phát, xác nhận thực dùng, kiểm kê có phê duyệt, lịch sử biến động) **đã có API thật** từ Tuần 8; trang Kho trên website dùng API này, không còn dữ liệu mẫu.
<!-- TV3-TUAN8-AUDIT:db-setup END -->

## Các API đã có

- `/api/auth`: đăng nhập, đăng ký, đăng xuất và đổi mật khẩu.
- `/api/accounts`: quản lý tài khoản nhân viên.
- `/api/customers`: quản lý khách hàng.
- `/api/services`: xem, tìm kiếm, thêm và cập nhật dịch vụ.
- `/api/technicians`: danh sách kỹ thuật viên để quản lý phân công.
- `/api/repair-orders` và `/api/repair-orders/{id}`: danh sách và chi tiết phiếu, xe, khách hàng, dịch vụ, người được phân công. Quản lý/lễ tân được xem; KTV chỉ xem phiếu của mình.
- `/api/repair-orders/{id}/technicians`: xem và thêm phân công cho phiếu sửa chữa.
- `/api/technicians/me/repair-orders`: kỹ thuật viên xem công việc của mình.
- `/api/repair-orders/receptions`: các phiếu tiếp nhận chưa có phiếu sửa chữa.
- `POST /api/repair-orders`: lập phiếu từ tiếp nhận và danh mục dịch vụ thật.
- `PUT /api/repair-orders/{id}/progress`: cập nhật trạng thái và ghi nhật ký.
- `PUT /api/repair-orders/{id}/services/{serviceId}/progress`: cập nhật từng dịch vụ.
- `/api/invoices`: lập và xem hóa đơn. `/api/invoices/{id}/payments`: ghi nhận tiền đã thu.
- `/api/bank-accounts`: tài khoản ngân hàng nhận tiền của gara; chỉ quản lý được sửa.
- `/api/customer/repairs`: khách xem tiến độ xe của mình, xác định theo tài khoản đăng nhập.
- `/api/customer/profile`, `/api/customers/{id}/vehicles`: hồ sơ và xe của khách đăng nhập.
- `/api/customers/me/history`: lịch sử sửa chữa hoàn tất và chi phí thực tế của chính khách hàng.
- `/api/vehicles`, `/api/spare-parts`, `/api/repair-orders/{id}/details`: xe, phụ tùng và hạng mục phiếu sửa chữa.
- `/api/inventory`, `/api/inventory/movements`: tồn kho và biến động thực tế.
- `/api/warehouse/imports`: nhập kho; mỗi chi tiết nhập tăng tồn đúng một lần.
- `/api/warehouse/exports`: cấp phát phụ tùng, chưa trừ tồn. Chỉ KTV liên quan được xác nhận thực dùng; tồn giảm tại thời điểm xác nhận.
- `/api/warehouse/checks`: kiểm kê do kho ghi nhận và quản lý duyệt/từ chối.

Ví dụ request và quyền truy cập: [Test API dịch vụ và phân công](docs/API_SERVICE_TECHNICIAN_ASSIGNMENT.md).

Luồng sửa chữa và thu tiền: [Cách dùng và test](docs/REPAIR_BILLING.md). Lịch hẹn, thao tác báo giá phía khách hàng, thông báo và báo cáo chưa có API đầy đủ; giao diện ghi rõ các phần này là `MOCK_ONLY`.

## Chạy test

Để có nhiều phiếu tiếp nhận, sửa chữa và hóa đơn phục vụ thử trên giao diện, xem [bộ dữ liệu test của Huy](database/seeds/README.md). File seed chạy riêng trên database local, không xóa dữ liệu đang có.

```powershell
.\mvnw.cmd test
```

Kiểm tra thêm với SQL Server trong `.env` (chỉ dùng database phát triển):

```powershell
.\mvnw.cmd "-Dtest=CustomerAccountSqlServerIT,RepairBillingSqlServerIT,StockUsageSqlServerIT" test
```

Test thêm dữ liệu trong transaction rồi rollback, không sửa schema hay xóa dữ liệu sẵn có. Số identity có thể tăng sau khi chạy test.

Xem hướng dẫn chạy toàn bộ project tại [`../README.md`](../README.md).

<!-- TV3-TUAN8-AUDIT:warehouse-api BEGIN -->
## API kho (Tuần 8)

- `GET /api/inventory`, `GET /api/inventory/movements`: tồn kho (tìm theo mã/tên/hãng, lọc tình trạng) và lịch sử biến động.
- `GET|POST /api/warehouse/imports`, `GET /api/warehouse/imports/{id}`: nhập kho (mỗi chi tiết nhập tăng tồn đúng một lần).
- `GET|POST /api/warehouse/exports`, `GET /api/warehouse/exports/{id}`: xuất kho = **cấp phát**, chưa trừ tồn. Kỹ thuật viên chỉ xem phiếu liên quan đến mình.
- `POST /api/warehouse/exports/{issueId}/items/{partId}/confirm`: kỹ thuật viên xác nhận số lượng thực dùng; chỉ lúc này tồn mới giảm, theo số lượng thực dùng.
- `GET|POST /api/warehouse/checks`, `GET /api/warehouse/checks/{id}`, `PUT /api/warehouse/checks/{id}/items/{partId}`, `POST /api/warehouse/checks/{id}/approve|reject`: kiểm kê; chỉ MANAGER duyệt hoặc từ chối, tồn chỉ đổi sau khi duyệt.
<!-- TV3-TUAN8-AUDIT:warehouse-api END -->

<!-- TV3-TUAN9-AUDIT:history-api BEGIN -->
## API lịch sử sửa chữa của khách hàng (Tuần 9)

Chỉ tài khoản `CUSTOMER`. Backend xác định khách hàng từ tài khoản trong JWT; **không có tham số `customerId`** nên khách hàng không thể xem dữ liệu của người khác.

- `GET /api/customers/me/history`: lịch sử sửa chữa/bảo dưỡng đã hoàn tất (`HOAN_TAT`), mới nhất trước. Tham số: `page` (từ 0, mặc định 0), `size` (mặc định 10, tối đa 50), `vehicleId` (lọc theo xe). Trả `items`, `page`, `size`, `totalElements`, `totalPages` — `totalElements` luôn là tổng đầy đủ, không bị cắt.
- `GET /api/customers/me/history/vehicles`: danh sách xe của khách hàng có lịch sử hoàn tất, dùng làm bộ lọc (không phụ thuộc trang).
- `GET /api/customers/me/history/{repairOrderId}`: chi tiết một lượt (dịch vụ, phụ tùng thực dùng, chi phí).

Xe không thuộc khách hàng, phiếu chưa hoàn tất hoặc phiếu của khách hàng khác đều trả 404 giống nhau. Dữ liệu được tổng hợp từ `PhieuSuaChua`, `PhieuTiepNhan`, `Xe`, `ChiTietDichVu`, `ChiTietPhuTung`, `DichVu`, `PhuTung` và `dbo.fn_TinhTongChiPhiSuaChua`, không có bảng lịch sử riêng.

Integration test trên SQL Server thật (không chạy trong `mvnw test`): đặt `RUN_SQLSERVER_IT=true` cùng `DB_URL`/`DB_USERNAME`/`DB_PASSWORD`, rồi chạy `.\mvnw.cmd -Dtest=RepairHistorySqlServerIT test`. Dữ liệu test được rollback.
<!-- TV3-TUAN9-AUDIT:history-api END -->

<!-- TV3-TUAN10-AUDIT:notifications-api BEGIN -->
## API thông báo và nhắc bảo dưỡng (Tuần 10)

Đã triển khai ở backend (Mobile vẫn nối mock cho đến khi được tích hợp). Chi tiết, JSON mẫu và mã lỗi: `backend/docs/API_NOTIFICATIONS.md`. Cần chạy migration `V004`.

- `GET /api/customers/me/notifications` (`page`, `size`), `GET /api/customers/me/notifications/unread-count`, `PATCH /api/customers/me/notifications/{notificationId}/read`, `PATCH /api/customers/me/notifications/read-all`: role `CUSTOMER`, khách hàng lấy từ JWT (không có `customerId` từ client).
- `POST|GET /api/maintenance-reminders`, `POST /api/maintenance-reminders/{id}/cancel`: role `ADMIN`, `MANAGER`, `RECEPTIONIST`.
- Thông báo lịch hẹn và tiến độ sửa chữa do trigger SQL Server tạo (V004); nhắc bảo dưỡng do scheduler (`app.reminders.enabled`, `app.reminders.cron`, múi giờ `Asia/Ho_Chi_Minh`).
- Integration test SQL Server thật (không chạy trong `mvnw test`): `RUN_SQLSERVER_IT=true` rồi `.\mvnw.cmd -Dtest=NotificationsSqlServerIT test`; kiểm thử SQL: `backend/database/Test_Notifications.sql`.
<!-- TV3-TUAN10-AUDIT:notifications-api END -->
