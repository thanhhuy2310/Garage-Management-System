# Backend

REST API của hệ thống gara, sử dụng Java 21, Spring Boot 3.5.6, Spring Security, JWT, Spring Data JPA và SQL Server.

## Chuẩn bị

1. Chạy `database/QuanLyGaraOTo.sql` trong SQL Server Management Studio.
2. Sao chép `.env.example` thành `.env`.
3. Điền kết nối SQL Server, `JWT_SECRET` và các biến còn lại trong `.env`.

File `.env` không được đưa lên Git.

## Chạy backend

```powershell
.\run-dev.ps1
```

Hoặc chạy main class `com.gara.quanlygara.QuanLyGaraApplication` trong IntelliJ IDEA.

API mặc định chạy tại `http://localhost:8080`. Có thể kiểm tra nhanh bằng:

```text
GET http://localhost:8080/api/health
```

## API hiện có

- `/api/auth`: đăng nhập, đăng ký, đăng xuất, lấy tài khoản hiện tại và đổi mật khẩu.
- `/api/accounts`: quản lý tài khoản và phân quyền nhân viên.
- `/api/customers`: xem, thêm, sửa và thay đổi trạng thái khách hàng.

Các endpoint tài khoản yêu cầu quyền quản trị. Endpoint khách hàng dành cho quản trị viên, quản lý và nhân viên tiếp nhận.

## Chạy test

```powershell
.\mvnw.cmd test
```

## Ghi chú database

Schema được quản lý bằng file SQL trong thư mục `database`. Cấu hình `ddl-auto=none` được giữ để Hibernate không tự thay đổi bảng.

Hướng dẫn chạy website và mobile nằm tại [`../README.md`](../README.md).
