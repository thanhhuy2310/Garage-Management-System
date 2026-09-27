# Frontend

Thư mục này chứa website của hệ thống gara.

Website có 3 khu vực chính:

- Trang giới thiệu và đặt lịch cho khách chưa đăng nhập.
- Trang khách hàng để quản lý xe, lịch hẹn, báo giá và tiến độ sửa chữa.
- Trang làm việc của nhân viên gara.

## Cách chạy

Backend cần được chạy trước. Sau đó mở terminal tại thư mục `frontend` và chạy:

```powershell
npm install
npm run dev
```

Mở `http://localhost:5173` để xem giao diện.

## Các lệnh cần dùng

```powershell
npm run dev
npm run build
npm run preview
npm run format
```

Kiểm tra lỗi TypeScript:

```powershell
.\node_modules\.bin\tsc.cmd --noEmit
```

Những phần đã kết nối backend nằm trong `src/api`. Một số màn hình chưa có API vẫn lấy dữ liệu từ `src/mock`.

Xem hướng dẫn chạy toàn bộ project tại [`../README.md`](../README.md).
