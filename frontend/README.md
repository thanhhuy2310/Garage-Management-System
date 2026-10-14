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

Lễ tân/quản lý/admin được lập phiếu từ tiếp nhận đã có trong SQL và bổ sung dịch vụ trước khi sửa. KTV được cập nhật tiến độ phiếu của mình, ghi nhật ký và hoàn tất từng dịch vụ. Quản lý/admin cũng được cập nhật. Xong tất cả dịch vụ mới được hoàn tất phiếu.

## Hóa đơn và thanh toán

Lễ tân/quản lý/admin mở **Hóa đơn** để lập hóa đơn từ phiếu hoàn tất, xem chi tiết và thu tiền nhiều lần. Tiền dịch vụ/phụ tùng lấy từ phiếu sửa chữa trong SQL; không dùng dữ liệu mẫu hay ngày thu tiền cố định.

Quản lý/admin có nút **Tài khoản ngân hàng** để lưu nhiều tài khoản. Chọn ngân hàng khi thu tiền để hiện QR. Chưa nhập số tài khoản thì không có QR; vẫn ghi nhận được giao dịch chuyển khoản đã nhận. QR không tự xác nhận thanh toán. Mã được ẩn sau 15 phút nhưng ảnh QR đã lưu không thể bị vô hiệu hóa tại ngân hàng.

Hướng dẫn chạy migration, quyền và test luồng: [Sửa chữa và thu tiền](../backend/docs/REPAIR_BILLING.md). Yêu cầu phụ tùng, tiếp nhận và những màn chưa nối API vẫn cần làm tiếp.

Code được chia thành `api/garage.ts` (gọi API), `types/garage.ts` (kiểu dữ liệu), `components/services`, `components/repairs` (form và giao diện), `hooks/useGarageQuery.ts` (tải dữ liệu, lỗi, tải lại). Trang trong `pages` chỉ ghép các phần này.

## Test giao diện

Cần cài Google Chrome. Sau `npm install`, chạy:

```powershell
npm run test:e2e
```

Test chạy ở 3 kích thước desktop/tablet/mobile, kiểm tra thêm/sửa dịch vụ, phân công, cập nhật tiến độ, lập hóa đơn, thu tiền, gửi lại khi mất phản hồi và QR. Fixture của các test này không được dùng trong ứng dụng.

Để test màn hình với SQL thật, chạy backend trên cổng 8080, rồi đặt tài khoản quản lý trong terminal:

```powershell
$env:GARAGE_TEST_USERNAME = "ten-tai-khoan-quan-ly"
$env:GARAGE_TEST_PASSWORD = "mat-khau"
npm run test:live
```

Test này đăng nhập và đọc dữ liệu, không tạo/sửa phiếu hay dịch vụ. Không đưa mật khẩu vào file code hoặc commit. Cổng 5177 dành cho test, không ảnh hưởng cổng dev 5173.

Xem hướng dẫn chạy toàn bộ project tại [`../README.md`](../README.md).
