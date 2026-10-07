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

Đăng nhập và theo dõi sửa chữa đã gọi backend. Tab **Theo dõi** lấy xe, trạng thái, dịch vụ, kỹ thuật viên và nhật ký từ SQL theo tài khoản khách đang đăng nhập. Kéo xuống để tải lại; tab **Đã kết thúc** xem phiếu hoàn tất/hủy. Không tự hiển thị tiến độ mẫu khi mất mạng hoặc chưa có dữ liệu.

Backend cần chạy migration V002 và V003 trước. Xem [cách thử luồng sửa chữa](../backend/docs/REPAIR_BILLING.md).

Các phần trang chủ, xe, đặt lịch, báo giá, thông báo và hồ sơ vẫn chưa đồng bộ hết với database. Dữ liệu ở các màn này còn dùng service mẫu; không dùng chúng để kiểm chứng tiến độ sửa chữa thật.

Xem hướng dẫn chạy toàn bộ project tại [`../README.md`](../README.md).
