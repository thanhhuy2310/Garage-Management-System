# Ứng dụng khách hàng

Ứng dụng Flutter dành cho khách hàng của Gara Ô Tô Thành Công. Người dùng có thể đăng nhập, quản lý xe, đặt lịch, xem báo giá, theo dõi sửa chữa, xem lịch sử và nhận thông báo.

## Chạy ứng dụng

```powershell
flutter pub get
flutter run
```

Ứng dụng yêu cầu Dart 3.13 trở lên.

## Kết nối backend

Khi chạy bằng Android Emulator, ứng dụng mặc định gọi API tại:

```text
http://10.0.2.2:8080/api
```

Khi chạy trên điện thoại thật, truyền IP của máy tính đang chạy backend:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api
```

Thay địa chỉ trong ví dụ bằng IP mạng nội bộ của máy tính. Hai thiết bị phải cùng mạng và Windows Firewall cần cho phép kết nối đến cổng `8080`.

## Kiểm tra mã nguồn

```powershell
flutter analyze
flutter test
```

Đăng nhập hiện đã sử dụng API Spring Boot. Dữ liệu xe, lịch hẹn, báo giá, sửa chữa và thông báo vẫn được quản lý cục bộ cho đến khi các API tương ứng hoàn thành.

Hướng dẫn chạy toàn bộ hệ thống nằm tại [`../README.md`](../README.md).
