# Garage Management System

Project khóa luận xây dựng hệ thống quản lý gara ô tô. Repository gồm website dành cho khách hàng và nhân viên, REST API Spring Boot và ứng dụng Flutter dành cho khách hàng.

## Cấu trúc project

```text
garage-management-system/
├── frontend/   Website React + TypeScript + Vite
├── backend/    REST API Java 21 + Spring Boot + SQL Server
├── mobile/     Ứng dụng khách hàng viết bằng Flutter
└── .run/       Cấu hình chạy dùng chung cho IntelliJ IDEA
```

## Chức năng hiện có

- Khách hàng: đăng ký, đăng nhập, quản lý xe, đặt lịch, xem báo giá, tiến độ sửa chữa, lịch sử và thông báo.
- Nhân viên gara: quản lý khách hàng, xe, lịch hẹn, tiếp nhận, sửa chữa, kho, hóa đơn và báo cáo.
- Phân quyền tài khoản theo các vai trò `ADMIN`, `MANAGER`, `RECEPTIONIST`, `TECHNICIAN`, `WAREHOUSE` và `CUSTOMER`.
- Thanh toán chuyển khoản bằng mã QR có thời gian hết hạn.

API thật hiện đã được nối cho đăng nhập, đăng ký, đổi mật khẩu, tài khoản và khách hàng. Một số màn hình nghiệp vụ còn sử dụng dữ liệu cục bộ trong lúc chờ bổ sung API tương ứng.

## Yêu cầu

- JDK 21
- SQL Server và SQL Server Management Studio
- Node.js 22 trở lên và npm
- Flutter SDK có Dart 3.13 trở lên nếu chạy ứng dụng mobile
- IntelliJ IDEA hoặc Android Studio

Backend đã có Maven Wrapper nên không cần cài Maven riêng.

## Chuẩn bị database

Mở SSMS và chạy file [`backend/database/QuanLyGaraOTo.sql`](backend/database/QuanLyGaraOTo.sql). Script tạo database `QuanLyGaraOTo`, các bảng, dữ liệu ban đầu và tài khoản dùng để kiểm tra.

Spring Boot chỉ đọc schema có sẵn và không tự tạo lại bảng (`ddl-auto=none`).

## Chạy backend

Sao chép `backend/.env.example` thành `backend/.env`, sau đó điền thông tin SQL Server và JWT:

```text
DB_URL
DB_USERNAME
DB_PASSWORD
JWT_SECRET
JWT_EXPIRATION
SERVER_PORT
```

`JWT_SECRET` phải có ít nhất 32 ký tự. File `.env` chỉ dùng trên máy cá nhân và đã được Git bỏ qua.

Chạy bằng PowerShell:

```powershell
cd backend
.\run-dev.ps1
```

Hoặc mở project bằng IntelliJ IDEA và chạy cấu hình **Garage Backend**.

Kiểm tra backend tại `http://localhost:8080/api/health`.

## Chạy website

```powershell
cd frontend
npm install
npm run dev
```

Website chạy tại `http://localhost:5173`. Trong chế độ phát triển, Vite chuyển các request `/api` sang backend ở cổng `8080`, vì vậy cần chạy backend trước khi đăng nhập.

Trong IntelliJ IDEA có thể chọn **Garage Full Stack** để chạy website và backend cùng lúc.

## Chạy ứng dụng Flutter

```powershell
cd mobile
flutter pub get
flutter run
```

Android Emulator dùng sẵn địa chỉ `http://10.0.2.2:8080/api`. Khi chạy trên điện thoại thật, truyền địa chỉ IP của máy đang chạy backend:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api
```

Thay `192.168.1.10` bằng địa chỉ IP trong mạng nội bộ của máy tính. Điện thoại và máy tính phải dùng cùng mạng Wi-Fi.

## Tài khoản kiểm tra

Các tài khoản dưới đây được tạo bởi script SQL và có chung mật khẩu `demo123`:

| Tên đăng nhập | Vai trò |
| --- | --- |
| `khach01` | Khách hàng |
| `tiepnhan` | Nhân viên tiếp nhận |
| `ktvbao`, `ktvhung` | Kỹ thuật viên |
| `kho` | Nhân viên kho |
| `manager` | Quản lý |
| `admin` | Quản trị viên |

Chỉ sử dụng các tài khoản này khi chạy project ở máy local.

## Kiểm tra trước khi bàn giao

```powershell
# Frontend
cd frontend
npm run build
.\node_modules\.bin\tsc.cmd --noEmit

# Backend
cd ..\backend
.\mvnw.cmd test

# Mobile
cd ..\mobile
flutter analyze
flutter test
```

## Lỗi thường gặp

- Mở `http://localhost:8080` chỉ thấy JSON: đây là cổng API; giao diện web nằm ở `http://localhost:5173`.
- Port `8080` đang được sử dụng: dừng backend đang chạy trước đó rồi chạy lại.
- Không kết nối được SQL Server: kiểm tra dịch vụ SQL Server, TCP/IP, port `1433` và thông tin trong `backend/.env`.
- Mobile chạy trên máy thật không đăng nhập được: kiểm tra IP máy tính, Windows Firewall và kết nối Wi-Fi của hai thiết bị.
