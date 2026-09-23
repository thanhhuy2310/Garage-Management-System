# Backend - Garage Management System

REST API dùng Java 21, Spring Boot 3.5.6, Maven Wrapper và SQL Server.

## Chạy nhanh

1. Chạy `database/QuanLyGaraOTo.sql` trong SQL Server/SSMS.
2. Sao chép `.env.example` thành `.env` và điền thông tin local. File `.env` đã được Git bỏ qua.
3. Chạy:

```powershell
.\run-dev.ps1
```

Script đọc `.env`, đưa các biến vào process và gọi Maven Wrapper. Spring Boot cũng tự import `.env` local, nên trong IntelliJ có thể chọn cấu hình **Garage Backend** hoặc chạy trực tiếp `QuanLyGaraApplication`.

Kiểm tra tại `http://localhost:8080/api/health`.

Hướng dẫn đầy đủ cho backend, frontend và IntelliJ nằm trong `../README.md`.
