# Garage Management System

Hệ thống quản lý gara ô tô gồm:

- `backend`: Spring Boot API và SQL Server.
- `frontend`: React Web cho nhân viên và khách hàng.
- `mobile`: Flutter dành cho khách hàng.

Các phân hệ chính gồm tài khoản và phân quyền, khách hàng, xe, lịch hẹn, tiếp nhận, sửa chữa, kỹ thuật viên, báo giá, bảo hiểm, kho, hóa đơn, thanh toán, thông báo và báo cáo thống kê. Web và Mobile lấy dữ liệu thật từ Backend.

## Cài đặt

Yêu cầu JDK 21, SQL Server, Node.js 22+ và Flutter SDK.

1. Chạy `backend/database/Script.sql` trên SQL Server để tạo schema.
2. Chạy migration bằng `backend/database/Update-GarageDatabase.ps1` hoặc theo thứ tự trong `backend/database/migrations/README.md`.
3. Sao chép `backend/.env.example` thành `backend/.env` và cấu hình kết nối SQL Server cùng `JWT_SECRET`.

## Chạy project

```powershell
cd backend
.\run-dev.ps1
```

```powershell
cd frontend
npm install
npm run dev
```

```powershell
cd mobile
flutter pub get
flutter run
```

Web mặc định chạy tại `http://localhost:5173`, Backend tại `http://localhost:8080`. Với điện thoại thật, truyền địa chỉ máy chạy Backend qua `API_BASE_URL`.

## Kiểm tra

```powershell
cd backend
.\mvnw.cmd test

cd ..\frontend
npx tsc --noEmit
npm run build

cd ..\mobile
flutter analyze
flutter test
```

Database sạch không có tài khoản mặc định. Quản trị viên đầu tiên được tạo bằng các biến `BOOTSTRAP_ADMIN_*` mô tả trong `backend/.env.example`.
