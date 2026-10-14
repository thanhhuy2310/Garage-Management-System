# Mobile

Đây là ứng dụng Flutter dành cho khách hàng của gara.

Các màn hình hiện có gồm đăng nhập, xe của tôi, đặt lịch, lịch hẹn, báo giá, tiến độ sửa chữa, lịch sử, thông báo và hồ sơ cá nhân.

## Cách chạy

Khởi động Android Emulator rồi chạy:

```powershell
flutter pub get
flutter run
```

Android Emulator sẽ gọi backend tại `http://10.0.2.2:8080/api`.

Nếu dùng điện thoại thật, thay IP dưới đây bằng IP của máy tính đang chạy backend:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api
```

Điện thoại và máy tính phải dùng cùng mạng Wi-Fi.

## Kiểm tra code

```powershell
flutter analyze
flutter test
```

<!-- TV3-TUAN9-AUDIT:backend-status BEGIN -->
Trạng thái kết nối backend:

- **Đăng nhập** gọi API backend (`/api/auth`).
- **Lịch sử sửa chữa, bảo dưỡng** gọi API backend thật (`GET /api/customers/me/history`): phân trang ("Tải thêm"), lọc theo xe, màn chi tiết gọi `GET /api/customers/me/history/{repairOrderId}`. Địa chỉ backend lấy từ `API_BASE_URL` (mặc định `http://10.0.2.2:8080/api` cho Android Emulator; điện thoại thật dùng `--dart-define=API_BASE_URL=http://<IP máy tính>:8080/api`).
- **Các màn hình còn lại** hiện vẫn dùng dữ liệu mẫu hoặc dữ liệu lưu trong ứng dụng, chưa đồng bộ với database, trừ khi được ghi rõ ở trên là đã tích hợp.
<!-- TV3-TUAN9-AUDIT:backend-status END -->

Xem hướng dẫn chạy toàn bộ project tại [`../README.md`](../README.md).
