# Garage Management System

Hệ thống quản lý gara gồm hai ứng dụng chạy độc lập:

```text
garage-management-system/
├── frontend/   # React + TypeScript + Vite
└── backend/    # Java 21 + Spring Boot + SQL Server
```

## Yêu cầu

- JDK 21
- IntelliJ IDEA
- SQL Server và SQL Server Management Studio (SSMS)
- Node.js/npm cho frontend

Không cần cài Maven toàn cục vì backend đã có Maven Wrapper.

## Cách chạy cả project

### 1. Tạo database

Mở SQL Server/SSMS và chạy file `backend/database/QuanLyGaraOTo.sql`. Database được sử dụng là `QuanLyGaraOTo`; Spring Boot không tự tạo lại schema (`ddl-auto=none`).

### 2. Thiết lập biến môi trường backend

Tham khảo `backend/.env.example` và khai báo các biến sau trong hệ điều hành hoặc trong Run Configuration cá nhân của IntelliJ:

```text
DB_URL
DB_USERNAME
DB_PASSWORD
JWT_SECRET
JWT_EXPIRATION
SERVER_PORT
```

`DB_PASSWORD` và `JWT_SECRET` là bắt buộc. `JWT_SECRET` cần dài ít nhất 32 ký tự. File `.env` chỉ là cấu hình cục bộ và đã được Git bỏ qua; Spring Boot không tự đọc file này nếu không có công cụ hỗ trợ, vì vậy cách đơn giản nhất trong IntelliJ là mở **Run > Edit Configurations > Garage Backend > Environment variables** và nhập các biến một lần trên máy của bạn.

### 3. Chạy backend

Cách 1 — IntelliJ IDEA:

1. Mở thư mục gốc `garage-management-system`.
2. Đợi IntelliJ import `backend/pom.xml` dưới dạng Maven project.
3. Chọn Project SDK 21.
4. Chọn cấu hình **Garage Backend** và nhấn **Run**.

Có thể chạy trực tiếp main class `com.gara.quanlygara.QuanLyGaraApplication` nếu IntelliJ chưa hiển thị cấu hình dùng chung.

Cách 2 — Maven Wrapper trên Windows:

```powershell
cd backend
$env:DB_PASSWORD="your_local_password"
$env:JWT_SECRET="your_local_secret_at_least_32_characters"
.\mvnw.cmd spring-boot:run
```

Cách 3 — build JAR:

```powershell
cd backend
.\mvnw.cmd clean package
java -jar target/garage-management-backend-0.0.1-SNAPSHOT.jar
```

### 4. Chạy frontend

Trong IntelliJ chọn **Garage Frontend**, hoặc chạy:

```powershell
cd frontend
npm install
npm run dev
```

Sau khi đã cấu hình backend, có thể chọn **Garage Full Stack** để chạy đồng thời frontend và backend.

### 5. Địa chỉ kiểm tra

- Frontend: http://localhost:5173
- Backend: http://localhost:8080
- Health check: http://localhost:8080/api/health

Backend hiện chưa tích hợp Swagger/OpenAPI.

## IntelliJ IDEA khuyến nghị

- Project SDK: JDK 21
- Language level: 21
- Build system: Maven, dùng Maven Wrapper
- Bật **Settings > Build, Execution, Deployment > Compiler > Annotation Processors > Enable annotation processing**.

Backend hiện không dùng Lombok hoặc MapStruct nên không cần cài plugin tương ứng.

## Xử lý lỗi thường gặp

- `Could not resolve placeholder 'DB_PASSWORD'`: chưa khai báo mật khẩu SQL Server trong môi trường chạy.
- `Could not resolve placeholder 'JWT_SECRET'`: chưa khai báo JWT secret hoặc secret quá ngắn.
- `Connection refused`/`Login failed for user`: kiểm tra SQL Server đang chạy, TCP/IP port `1433`, tài khoản và database `QuanLyGaraOTo`.
- Port `8080` đang bận: đóng ứng dụng đang dùng port hoặc đặt `SERVER_PORT` sang port khác.
- Frontend không gọi được API: mặc định backend chỉ cho phép các origin local đã khai báo, gồm `http://localhost:5173`.
