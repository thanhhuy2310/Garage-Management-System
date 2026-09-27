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

Đăng nhập đã gọi backend. Các dữ liệu khác hiện vẫn được lưu và xử lý trong ứng dụng, chưa đồng bộ với database.

Xem hướng dẫn chạy toàn bộ project tại [`../README.md`](../README.md).
