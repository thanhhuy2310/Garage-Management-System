# Backend

Thư mục này chứa API của hệ thống gara. Backend dùng Java 21, Spring Boot và SQL Server.

## Cách chạy

1. Nếu chưa có database, chạy `database/QuanLyGaraOTo.sql` trong SQL Server Management Studio. Database đang có dữ liệu thì không chạy lại file này.
2. Chọn database `QuanLyGaraOTo`, chạy lần lượt `database/migrations/V002__repair_progress_and_payment_requests.sql` và `V003__receiving_bank_accounts.sql`. Hai file chỉ bổ sung bảng/cột, không xóa dữ liệu. Có thể chạy lại an toàn.
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

## Các API đã có

- `/api/auth`: đăng nhập, đăng ký, đăng xuất và đổi mật khẩu.
- `/api/accounts`: quản lý tài khoản nhân viên.
- `/api/customers`: quản lý khách hàng.
- `/api/services`: xem, tìm kiếm, thêm và cập nhật dịch vụ.
- `/api/technicians`: danh sách kỹ thuật viên để quản lý phân công.
- `/api/repair-orders` và `/api/repair-orders/{id}`: danh sách và chi tiết phiếu, xe, khách hàng, dịch vụ, người được phân công. Quản lý/admin/lễ tân được xem; KTV chỉ xem phiếu của mình.
- `/api/repair-orders/{id}/technicians`: xem và thêm phân công cho phiếu sửa chữa.
- `/api/technicians/me/repair-orders`: kỹ thuật viên xem công việc của mình.
- `/api/repair-orders/receptions`: các phiếu tiếp nhận chưa có phiếu sửa chữa.
- `POST /api/repair-orders`: lập phiếu từ tiếp nhận và danh mục dịch vụ thật.
- `PUT /api/repair-orders/{id}/progress`: cập nhật trạng thái và ghi nhật ký.
- `PUT /api/repair-orders/{id}/services/{serviceId}/progress`: cập nhật từng dịch vụ.
- `/api/invoices`: lập và xem hóa đơn. `/api/invoices/{id}/payments`: ghi nhận tiền đã thu.
- `/api/bank-accounts`: tài khoản ngân hàng nhận tiền của gara; chỉ quản lý/admin được sửa.
- `/api/customer/repairs`: khách xem tiến độ xe của mình, xác định theo tài khoản đăng nhập.

Ví dụ request và quyền truy cập: [Test API dịch vụ và phân công](docs/API_SERVICE_TECHNICIAN_ASSIGNMENT.md).

Luồng sửa chữa và thu tiền: [Cách dùng và test](docs/REPAIR_BILLING.md). Xe, lịch hẹn, tiếp nhận, kho và báo giá vẫn chưa có API đầy đủ; phần lập phiếu sửa chữa dùng những phiếu tiếp nhận đã có trong SQL.

## Chạy test

```powershell
.\mvnw.cmd test
```

Kiểm tra thêm với SQL Server trong `.env` (chỉ dùng database phát triển):

```powershell
.\mvnw.cmd "-Dtest=SqlServerApiIT,RepairBillingSqlServerIT" test
```

Test thêm dữ liệu trong transaction rồi rollback, không sửa schema hay xóa dữ liệu sẵn có. Số identity có thể tăng sau khi chạy test.

Xem hướng dẫn chạy toàn bộ project tại [`../README.md`](../README.md).
