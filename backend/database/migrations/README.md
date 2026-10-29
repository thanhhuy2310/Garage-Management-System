<!-- TV3-TUAN8 -->
# Thứ tự cập nhật database

Các file này là script SQL chạy thủ công, không phải Flyway. Hai nhánh lịch sử đã tạo trùng số `V002` và `V003`, vì vậy không chạy theo thứ tự tên file. Trên database mới, dùng đúng thứ tự sau:

| Bước | File | Nội dung |
| --- | --- | --- |
| 1 | `../QuanLyGaraOTo.sql` | Schema và dữ liệu nền |
| 2 | `V001__add_customer_status.sql` | Trạng thái khách hàng |
| 3 | `V002__repair_progress_and_payment_requests.sql` | Nhật ký sửa chữa và mã chống ghi nhận thanh toán lặp |
| 4 | `V003__receiving_bank_accounts.sql` | Tài khoản nhận tiền của gara |
| 5 | `V004__service_status.sql` | Cho phép ngừng cung cấp dịch vụ mà vẫn giữ lịch sử |
| 6 | `V002__warehouse_actual_used_and_stock_check.sql` | Thực dùng/hoàn trả phụ tùng và kiểm kê có phê duyệt |
| 7 | `V003__confirm_usage_row_lock.sql` | Khóa dòng khi kỹ thuật viên xác nhận thực dùng |
| 8 | `../patches/Repair_Safety_Procedures.sql` | Khóa hóa đơn trước khi cộng tiền thanh toán |
| 9 | `V004__customer_notifications_and_maintenance_reminders.sql` | Thông báo khách hàng và lịch nhắc bảo dưỡng |
| 10 | `V005__insurance_company_policy.sql` | Danh mục công ty và hợp đồng bảo hiểm |

Không chạy lại `QuanLyGaraOTo.sql` trên database đã có dữ liệu. Các file từ bước 2 đến bước 8 đều giữ dữ liệu hiện có và hỗ trợ chạy lại. Khi dùng `sqlcmd`, bật `QUOTED_IDENTIFIER` bằng tùy chọn `-I`.

Database phát triển local đã được xác nhận áp dụng tám bước đầu vào ngày 15/10/2026. Bước 9 và 10 phải kiểm tra, áp dụng riêng trên từng môi trường; không suy đoán chúng đã chạy. Có thể xác nhận phần kho bằng `../Test_Warehouse.sql`; script tự dọn dữ liệu kiểm thử.

`V002__warehouse_actual_used_and_stock_check.sql` và `V003__confirm_usage_row_lock.sql` là phần kho tích hợp từ nhánh của Cẩm. Không đổi tên các file đã chia sẻ để tránh làm mất dấu phiên bản của thành viên.

## Kiểm tra đồng thời thủ công

1. Tạo một chi tiết phiếu xuất chưa xác nhận như mục T5 trong `../Test_Warehouse.sql`.
2. Cửa sổ SSMS A mở transaction rồi gọi `sp_XacNhanSuDungPhuTung`, chưa commit.
3. Cửa sổ B gọi cùng procedure với cùng phiếu và phụ tùng; B phải chờ A.
4. Sau khi A commit, B phải nhận lỗi 50012. Tồn kho và `BienDongKho` chỉ thay đổi một lần.
