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

## Các API đã có

- `/api/auth`: đăng nhập, đăng ký, đăng xuất và đổi mật khẩu.
- `/api/accounts`: quản lý tài khoản nhân viên.
- `/api/customers`: quản lý khách hàng.
- `/api/services`: xem, tìm kiếm, thêm và cập nhật dịch vụ.
- `/api/technicians`: danh sách kỹ thuật viên để quản lý phân công.
- `/api/repair-orders` và `/api/repair-orders/{id}`: danh sách và chi tiết phiếu, xe, khách hàng, dịch vụ, người được phân công. Quản lý/admin/lễ tân được xem; KTV chỉ xem phiếu của mình.
- `/api/repair-orders/{id}/technicians`: xem và thêm phân công cho phiếu sửa chữa.
- `/api/technicians/me/repair-orders`: kỹ thuật viên xem công việc của mình.

Ví dụ request và quyền truy cập: [Test API dịch vụ và phân công](docs/API_SERVICE_TECHNICIAN_ASSIGNMENT.md).

Các nghiệp vụ xe, lịch hẹn, sửa chữa, kho, báo giá và hóa đơn chưa có API đầy đủ.

## Chạy test

```powershell
.\mvnw.cmd test
```

Kiểm tra thêm với SQL Server trong `.env` (chỉ dùng database phát triển):

```powershell
.\mvnw.cmd "-Dtest=SqlServerApiIT" test
```

Test thêm dữ liệu trong transaction rồi rollback, không sửa schema hay xóa dữ liệu sẵn có. Số identity có thể tăng sau khi chạy test.

Xem hướng dẫn chạy toàn bộ project tại [`../README.md`](../README.md).
