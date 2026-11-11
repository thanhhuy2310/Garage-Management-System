<!-- TV3-TUAN8 -->
# Thứ tự cập nhật database

Các file này là script SQL chạy thủ công, không phải Flyway. Hai nhánh lịch sử đã tạo trùng số `V002` và `V003`, vì vậy không chạy theo thứ tự tên file. Trên database mới, dùng đúng thứ tự sau:

| Bước | File | Nội dung |
| --- | --- | --- |
| 1 | `../Script.sql` | Schema thuần, không có dữ liệu mẫu |
| 2 | `V001__add_customer_status.sql` | Trạng thái khách hàng |
| 3 | `V002__repair_progress_and_payment_requests.sql` | Nhật ký sửa chữa và mã chống ghi nhận thanh toán lặp |
| 4 | `V003__receiving_bank_accounts.sql` | Tài khoản nhận tiền của gara |
| 5 | `V004__service_status.sql` | Cho phép ngừng cung cấp dịch vụ mà vẫn giữ lịch sử |
| 6 | `V002__warehouse_actual_used_and_stock_check.sql` | Thực dùng/hoàn trả phụ tùng và kiểm kê có phê duyệt |
| 7 | `V003__confirm_usage_row_lock.sql` | Khóa dòng khi kỹ thuật viên xác nhận thực dùng |
| 8 | `../patches/Repair_Safety_Procedures.sql` | Khóa hóa đơn trước khi cộng tiền thanh toán |
| 9 | `V004__customer_notifications_and_maintenance_reminders.sql` | Thông báo khách hàng và lịch nhắc bảo dưỡng |
| 10 | `V005__insurance_company_policy.sql` | Danh mục công ty và hợp đồng bảo hiểm |
| 11 | `V006__insurance_claim.sql` | Hồ sơ tổn thất và nhật ký tạo hồ sơ |
| 12 | `V007__insurance_owner_names.sql` | Tên chủ xe trên đăng ký và giấy chứng nhận bảo hiểm |
| 13 | `V008__appointment_workflow.sql` | Phiên bản lịch hẹn, cấu hình khung giờ, nhật ký thao tác; không seed sức chứa |
| 14 | `V009__quotation_workflow.sql` | Phiên bản báo giá, snapshot lịch sử; đối chiếu phụ tùng thực dùng với báo giá đã duyệt |
| 15 | `V010__reception_workflow.sql` | Liên kết lịch hẹn duy nhất, số km tiếp nhận, nhân viên và phiên bản; giữ phiếu cũ |
| 16 | `V011__customer_contact_messages.sql` | Lưu lời nhắn từ form liên hệ và trạng thái đã đọc; không tạo dữ liệu mẫu |

V008 giữ nguyên lịch cũ, chạy lại an toàn. Quản lý cấu hình khung giờ qua Web/API trước khi khách đặt mới. Mặc định không mở khung giờ. Thay đổi cấu hình chỉ ảnh hưởng nhận lịch mới, không hủy lịch đã có. Không cấp cho ứng dụng khác quyền ghi trực tiếp LichHen bỏ qua khóa nghiệp vụ của API.

Database kiểm chứng riêng có thể tạo bằng `../Initialize_VerificationDatabase.ps1`. Script từ chối database đã tồn tại; không dùng để khởi tạo lại môi trường đang có dữ liệu.

V009 không đổi nội dung báo giá cũ, không bỏ unique một báo giá hiện hành/phiếu. Nội dung trước tích hợp được lưu snapshot khi lần đầu thay đổi qua API, với actor để trống vì không thể suy đoán người thực hiện cũ. Trigger xác nhận phụ tùng bảo vệ cả API và procedure SQL cũ: nếu thực dùng vượt báo giá hoặc sai giá, transaction phải rollback. Các fixture kho phải có chi tiết báo giá thật, không chỉ một header đã xác nhận. Khi rollback ứng dụng, giữ các cột và lịch sử bổ sung; không xóa lịch sử đã duyệt. Script dùng database đang chọn, không chứa USE cố định; chạy với `sqlcmd -I -f 65001 -d <database>`.

Không chạy lại `Script.sql` trên database đã có dữ liệu. Các migration giữ dữ liệu hiện có. Khi dùng `sqlcmd`, bật `QUOTED_IDENTIFIER` bằng tùy chọn `-I`.

Database phát triển local đã được xác nhận áp dụng tám bước đầu vào ngày 15/10/2026. Bước 9–12 phải kiểm tra, áp dụng riêng trên từng môi trường; không suy đoán chúng đã chạy. Có thể xác nhận phần kho bằng `../Test_Warehouse.sql`; script tự dọn dữ liệu kiểm thử.

Để tạo database test sạch riêng và áp dụng đúng thứ tự này, chạy `../Initialize_Clean_Database.ps1 -DatabaseName <ten_database_test>`. Script từ chối database đã tồn tại và không chạy file trong `seeds/`.

`V002__warehouse_actual_used_and_stock_check.sql` và `V003__confirm_usage_row_lock.sql` là phần kho tích hợp từ nhánh của Cẩm. Không đổi tên các file đã chia sẻ để tránh làm mất dấu phiên bản của thành viên.

## Kiểm tra đồng thời thủ công

1. Tạo một chi tiết phiếu xuất chưa xác nhận như mục T5 trong `../Test_Warehouse.sql`.
2. Cửa sổ SSMS A mở transaction rồi gọi `sp_XacNhanSuDungPhuTung`, chưa commit.
3. Cửa sổ B gọi cùng procedure với cùng phiếu và phụ tùng; B phải chờ A.
4. Sau khi A commit, B phải nhận lỗi 50012. Tồn kho và `BienDongKho` chỉ thay đổi một lần.
