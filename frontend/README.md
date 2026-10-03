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

## Dịch vụ và phân công kỹ thuật viên

- Đăng nhập bằng tài khoản **quản lý hoặc admin**, mở **Dịch vụ** để thêm/sửa dịch vụ. Lưu xong sẽ ghi vào SQL Server.
- Mở **Phiếu sửa chữa**, chọn **Chi tiết & phân công**, rồi bấm **Phân công KTV**. Chọn người, nhập nội dung công việc và xác nhận.
- KTV đăng nhập vào **Công việc của tôi** để xem những phiếu được phân công. Lễ tân được xem phiếu nhưng không được phân công.
- Danh sách xe, khách hàng, dịch vụ trên phiếu và KTV đều lấy từ backend. Chưa có dữ liệu thì hiện danh sách trống, không tự thêm dữ liệu mẫu.

Phần này hiện hỗ trợ xem phiếu và phân công. Tạo phiếu từ tiếp nhận, bắt đầu/hoàn tất sửa chữa, yêu cầu phụ tùng chưa có API đầy đủ; các nút thao tác giả ở màn phiếu và công việc KTV đã được bỏ. Những màn khác chưa được chuyển sang backend trong thay đổi này.

Code được chia thành `api/garage.ts` (gọi API), `types/garage.ts` (kiểu dữ liệu), `components/services`, `components/repairs` (form và giao diện), `hooks/useGarageQuery.ts` (tải dữ liệu, lỗi, tải lại). Trang trong `pages` chỉ ghép các phần này.

## Test giao diện

Cần cài Google Chrome. Sau `npm install`, chạy:

```powershell
npm run test:e2e
```

Test chạy ở 3 kích thước desktop/tablet/mobile. Dữ liệu giả chỉ nằm trong file test để kiểm tra thêm/sửa, lỗi mạng, phân công trùng và phân quyền hiển thị; không được dùng trong ứng dụng.

Để test màn hình với SQL thật, chạy backend trên cổng 8080, rồi đặt tài khoản quản lý trong terminal:

```powershell
$env:GARAGE_TEST_USERNAME = "ten-tai-khoan-quan-ly"
$env:GARAGE_TEST_PASSWORD = "mat-khau"
npm run test:live
```

Test này đăng nhập và đọc dữ liệu, không tạo/sửa phiếu hay dịch vụ. Không đưa mật khẩu vào file code hoặc commit. Cổng 5177 dành cho test, không ảnh hưởng cổng dev 5173.

Xem hướng dẫn chạy toàn bộ project tại [`../README.md`](../README.md).
