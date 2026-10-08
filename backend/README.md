# Backend

Thư mục này chứa API của hệ thống gara. Backend dùng Java 21, Spring Boot và SQL Server.

## Cách chạy

1. Chạy file `database/QuanLyGaraOTo.sql` trong SQL Server Management Studio.
2. Sao chép `.env.example` thành `.env` và điền thông tin kết nối SQL Server.
3. Chạy lệnh:

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
- `/api/repair-orders/{id}/technicians`: xem và thêm phân công cho phiếu sửa chữa.
- `/api/technicians/me/repair-orders`: kỹ thuật viên xem công việc của mình.

Ví dụ request và quyền truy cập: [Test API dịch vụ và phân công](docs/API_SERVICE_TECHNICIAN_ASSIGNMENT.md).

Các nghiệp vụ xe, lịch hẹn, sửa chữa, báo giá và hóa đơn chưa có API đầy đủ.

## Chạy test

```powershell
.\mvnw.cmd test
```

Xem hướng dẫn chạy toàn bộ project tại [`../README.md`](../README.md).

<!-- TV3-TUAN8-AUDIT:warehouse-api BEGIN -->
## API kho (Tuần 8)

- `GET /api/inventory`, `GET /api/inventory/movements`: tồn kho (tìm theo mã/tên/hãng, lọc tình trạng) và lịch sử biến động.
- `GET|POST /api/warehouse/imports`, `GET /api/warehouse/imports/{id}`: nhập kho (mỗi chi tiết nhập tăng tồn đúng một lần).
- `GET|POST /api/warehouse/exports`, `GET /api/warehouse/exports/{id}`: xuất kho = **cấp phát**, chưa trừ tồn. Kỹ thuật viên chỉ xem phiếu liên quan đến mình.
- `POST /api/warehouse/exports/{issueId}/items/{partId}/confirm`: kỹ thuật viên xác nhận số lượng thực dùng; chỉ lúc này tồn mới giảm, theo số lượng thực dùng.
- `GET|POST /api/warehouse/checks`, `GET /api/warehouse/checks/{id}`, `PUT /api/warehouse/checks/{id}/items/{partId}`, `POST /api/warehouse/checks/{id}/approve|reject`: kiểm kê; chỉ MANAGER duyệt hoặc từ chối, tồn chỉ đổi sau khi duyệt.
<!-- TV3-TUAN8-AUDIT:warehouse-api END -->
