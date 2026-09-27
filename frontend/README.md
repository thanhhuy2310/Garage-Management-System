# Frontend

Website quản lý gara được viết bằng React, TypeScript, Vite và Tailwind CSS. Website có phần công khai, khu vực khách hàng và màn hình làm việc theo vai trò nhân viên.

## Chạy project

Yêu cầu Node.js 22 trở lên và npm.

```powershell
npm install
npm run dev
```

Mặc định website chạy tại `http://localhost:5173`.

Frontend gọi API bằng đường dẫn `/api`. Khi chạy local, Vite chuyển tiếp request sang Spring Boot tại `http://localhost:8080`, vì vậy backend cần được khởi động trước khi đăng nhập.

## Các lệnh thường dùng

```powershell
npm run dev       # chạy môi trường phát triển
npm run build     # tạo bản build production
npm run preview   # xem lại bản build
npm run format    # định dạng mã nguồn
```

Kiểm tra TypeScript:

```powershell
.\node_modules\.bin\tsc.cmd --noEmit
```

## Thư mục chính

- `src/api`: cấu hình gọi API và lưu phiên đăng nhập.
- `src/components`: component dùng chung và các phần của trang công khai.
- `src/features`: chức năng được tách theo nghiệp vụ.
- `src/layouts`: layout công khai, khách hàng và quản trị.
- `src/pages`: các trang của website.
- `src/mock`: dữ liệu tạm cho những nghiệp vụ chưa có API.

Hướng dẫn chạy toàn bộ hệ thống nằm tại [`../README.md`](../README.md).
