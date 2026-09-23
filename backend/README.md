# Backend - Garage Management System

REST API dùng Java 21, Spring Boot 3.5.6, Maven Wrapper và SQL Server.

## Chạy nhanh

1. Chạy `database/QuanLyGaraOTo.sql` trong SQL Server/SSMS.
2. Khai báo `DB_PASSWORD` và `JWT_SECRET`; các biến tùy chọn nằm trong `.env.example`.
3. Trong IntelliJ chọn **Garage Backend**, hoặc chạy:

```powershell
.\mvnw.cmd spring-boot:run
```

Kiểm tra tại `http://localhost:8080/api/health`.

Hướng dẫn đầy đủ cho backend, frontend và IntelliJ nằm trong `../README.md`.
