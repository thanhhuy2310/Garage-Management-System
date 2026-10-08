# Garage Management System

Đây là project quản lý gara ô tô, gồm 3 phần:

- `frontend`: website cho khách hàng và nhân viên gara.
- `backend`: API Spring Boot kết nối SQL Server.
- `mobile`: ứng dụng Flutter dành cho khách hàng.

## Project đang làm tới đâu?

Website đã có giao diện cho các công việc chính của gara như quản lý khách hàng, xe, lịch hẹn, tiếp nhận, sửa chữa, báo giá, kho, hóa đơn và báo cáo.

Ứng dụng mobile có các màn hình đăng nhập, quản lý xe, đặt lịch, xem báo giá, theo dõi sửa chữa, lịch sử và thông báo.

Các phần đăng nhập, đăng ký, đổi mật khẩu, tài khoản và khách hàng đã kết nối backend và SQL Server. Những phần còn lại vẫn đang dùng dữ liệu mẫu hoặc dữ liệu lưu trên máy, cần làm thêm API khi phát triển tiếp.

## Cần cài gì?

- JDK 21
- SQL Server và SQL Server Management Studio
- Node.js 22 trở lên
- Flutter SDK nếu cần chạy ứng dụng mobile
- IntelliJ IDEA hoặc Android Studio

Không cần cài Maven riêng vì trong project đã có Maven Wrapper.

## 1. Tạo database

Mở SQL Server Management Studio và chạy file:

```text
backend/database/QuanLyGaraOTo.sql
```

Script sẽ tạo database `QuanLyGaraOTo` cùng dữ liệu cần thiết để chạy thử.

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

## 2. Chạy backend

Sao chép file:

```text
backend/.env.example
```

thành:

```text
backend/.env
```

Sau đó điền tài khoản SQL Server và `JWT_SECRET`. Chuỗi `JWT_SECRET` cần có ít nhất 32 ký tự.

Chạy bằng PowerShell:

```powershell
cd backend
.\run-dev.ps1
```

Khi backend chạy thành công, mở `http://localhost:8080/api/health`. Nếu thấy trạng thái `OK` là được.

## 3. Chạy website

Mở thêm một cửa sổ terminal:

```powershell
cd frontend
npm install
npm run dev
```

Mở website tại `http://localhost:5173`.

Không mở `http://localhost:8080` để xem giao diện vì cổng `8080` chỉ dùng cho backend.

## 4. Chạy ứng dụng mobile

Khởi động Android Emulator rồi chạy:

```powershell
cd mobile
flutter pub get
flutter run
```

Nếu chạy trên điện thoại thật, điện thoại và máy tính phải cùng mạng Wi-Fi. Chạy lệnh sau và thay IP trong ví dụ bằng IP của máy tính:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api
```

## Chạy bằng IntelliJ IDEA

Project đã có sẵn các cấu hình:

- **Garage Backend**: chạy backend.
- **Garage Frontend**: chạy website.
- **Garage Full Stack**: chạy website và backend cùng lúc.

Ứng dụng Flutter chạy riêng bằng Android Emulator hoặc thiết bị thật.

## Tài khoản dùng để kiểm tra

Mật khẩu chung: `demo123`

| Tên đăng nhập | Dùng cho |
| --- | --- |
| `khach01` | Khách hàng |
| `tiepnhan` | Nhân viên tiếp nhận |
| `ktvbao`, `ktvhung` | Kỹ thuật viên |
| `kho` | Nhân viên kho |
| `manager` | Quản lý |
| `admin` | Quản trị viên |

## Kiểm tra code

Frontend:

```powershell
cd frontend
npm run build
.\node_modules\.bin\tsc.cmd --noEmit
```

Backend:

```powershell
cd backend
.\mvnw.cmd test
```

Mobile:

```powershell
cd mobile
flutter analyze
flutter test
```

## Một số lỗi thường gặp

- Backend báo thiếu `DB_PASSWORD` hoặc `JWT_SECRET`: kiểm tra lại file `backend/.env`.
- Không kết nối được SQL Server: kiểm tra dịch vụ SQL Server, port `1433`, tài khoản và mật khẩu.
- Port `8080` đang bận: có thể backend đã chạy ở một cửa sổ khác. Dừng tiến trình cũ rồi chạy lại.
- Mobile trên điện thoại thật không đăng nhập được: kiểm tra IP máy tính, Windows Firewall và mạng Wi-Fi.
