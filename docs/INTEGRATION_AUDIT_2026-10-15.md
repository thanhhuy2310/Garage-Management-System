# Kết quả tích hợp và rà soát nghiệp vụ — 15/10/2026

Nhánh làm việc: `integration`. Nhánh `main` không bị sửa. Mã nguồn từ bảy commit của Cẩm trên `feature/cam-mobile-history` đã được tích hợp cùng phần sửa chữa, thanh toán, hồ sơ khách hàng và giao diện hiện có.

## Trạng thái module

| Module | Trạng thái | Nguồn dữ liệu / giới hạn |
| --- | --- | --- |
| Đăng nhập, đăng ký, phiên đăng nhập, đổi mật khẩu | REAL | Spring Boot + SQL Server; JWT gắn với ID, mật khẩu, vai trò và liên kết actor hiện tại |
| Quản lý tài khoản | REAL | Chỉ ADMIN; ADMIN không đi vào màn vận hành gara |
| Hồ sơ khách hàng | REAL đọc | Khách lấy hồ sơ từ tài khoản đăng nhập; cập nhật hồ sơ chưa có API |
| Khách hàng | REAL | API và SQL Server |
| Xe | REAL | Web/Flutter dùng API; khách chỉ xem/thêm xe của chính mình |
| Danh mục dịch vụ | REAL | Có trạng thái đang/ngừng cung cấp; dịch vụ ngừng vẫn giữ lịch sử |
| Phụ tùng | REAL | API và SQL Server |
| Phiếu sửa chữa và nhật ký tiến độ | REAL | KTV chỉ thấy/cập nhật phiếu được phân công |
| Chi tiết dịch vụ/phụ tùng | REAL | Chỉ sửa trước khi khách xác nhận báo giá và trước khi bắt đầu sửa |
| Phân công kỹ thuật viên | REAL | Chỉ MANAGER; yêu cầu báo giá đã xác nhận |
| Nhập kho, xuất kho, tồn, biến động | REAL | Xuất kho chưa trừ tồn; chỉ trừ khi đúng KTV xác nhận thực dùng |
| Kiểm kê kho | REAL | WAREHOUSE ghi nhận, MANAGER duyệt/từ chối có khóa dòng |
| Hóa đơn và thanh toán | REAL | Lập sau hoàn tất; phụ tùng phải khớp thực dùng; thanh toán có khóa hóa đơn và mã chống lặp |
| Lịch sử khách hàng | REAL | Web/Flutter lấy từ phiếu hoàn tất thuộc xe của tài khoản đăng nhập |
| Tổng quan quản lý | MIXED | Phiếu sửa chữa và cảnh báo kho REAL; lịch hẹn, báo giá và biểu đồ ghi rõ `MOCK_ONLY` |
| Lịch hẹn Web/Flutter | MOCK_ONLY | Schema có `LichHen`, chưa có API |
| Khách xác nhận/từ chối báo giá | MOCK_ONLY | Schema/procedure có, chưa có API xác thực theo khách hàng |
| Thông báo khách hàng | MOCK_ONLY | Schema có `ThongBao`, chưa có API theo tài khoản |
| Báo cáo quản trị | MOCK_ONLY | Chưa có API tổng hợp; fixture được tách riêng và có nhãn |
| Quản lý hồ sơ nhân viên | MOCK_ONLY | Chưa có API CRUD nhân viên |

## Luồng nghiệp vụ đã chặn ở backend

1. Chi tiết dự kiến được chốt trước khi báo giá được khách xác nhận.
2. Chưa có báo giá đã xác nhận thì không được phân công, bắt đầu sửa hoặc cấp phụ tùng.
3. Kỹ thuật viên chỉ đọc/cập nhật công việc và phiếu xuất liên quan tới chính mình.
4. Cấp phát phụ tùng không đổi tồn kho. Tồn chỉ giảm theo số lượng thực dùng do KTV xác nhận; số còn lại là hoàn trả.
5. Không hoàn tất phiếu hoặc lập hóa đơn khi còn dòng xuất chưa xác nhận hay số phụ tùng tính tiền lệch thực dùng.
6. Tổng thanh toán không vượt hóa đơn; yêu cầu lặp không thu tiền lần hai; thao tác đồng thời khóa dòng hóa đơn.
7. Khách hàng lấy ID từ tài khoản đã xác thực, không lấy `customerId` do client tự chọn cho hồ sơ, tiến độ hay lịch sử.

## Database gap và phần chưa triển khai

- `DATABASE GAP`: chưa có cơ chế phiên bản migration duy nhất; hai nhánh cũ có tên `V002`/`V003` trùng nhau. Thứ tự chạy thủ công đã được ghi rõ, không tạo thêm bảng theo suy đoán.
- `NOT_IMPLEMENTED`: API lịch hẹn, API báo giá phía khách hàng, API thông báo, API báo cáo và API cập nhật hồ sơ khách hàng.
- `CHƯA ĐỦ CĂN CỨ TỪ TÀI LIỆU`: chính sách để ADMIN kiêm tác nghiệp gara. Bản hiện tại giữ ADMIN chỉ quản lý tài khoản; MANAGER chịu trách nhiệm phân công và phê duyệt kho.
- Giá phụ tùng nhiều lần xuất phải thống nhất. Nếu giá danh mục thay đổi giữa các lần xác nhận, hệ thống từ chối để người quản lý xử lý thay vì tự định giá lại lịch sử.

## Dữ liệu demo

`backend/database/seeds/Seed_Integrated_Demo.sql` tạo tám tình huống gắn kết, dùng mốc thời gian quá khứ/hiện tại/tương lai và các trạng thái hiện có. Script đã được chạy trên database phát triển local. Tài khoản demo dùng mật khẩu `demo123`, không có tài khoản ngân hàng giả và không phát sinh giao dịch bên ngoài.

## Kiểm thử

- Backend: test đơn vị và API trên H2; test tích hợp hồ sơ, sửa chữa, thanh toán và xác nhận thực dùng trên SQL Server local.
- Web: TypeScript, production build và Playwright trên desktop/tablet/mobile.
- Flutter: analyze và toàn bộ widget/service test; adapter API có kiểm thử token, hồ sơ, xe, đổi mật khẩu, lỗi phiên và tiền có phần lẻ.
- SQL: migration chạy trên `QuanLyGaraOTo`; `Test_Warehouse.sql` kiểm tra procedure kho và tự dọn dữ liệu thử.

Các test trình duyệt dùng route fixture để kiểm tra UI được ghi là kiểm thử giao diện mock. Kiểm thử SQL Server xác nhận luồng dữ liệu thật; hai loại không được báo chung là end-to-end thật.
