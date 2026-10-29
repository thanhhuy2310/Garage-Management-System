# Đánh giá trạng thái hoàn thiện dự án

Ngày đánh giá: 29/10/2026. Nhánh: `integration`. Đây là checkpoint thực tế; **dự án chưa hoàn thành toàn bộ master task**.

## Đã thực hiện và kiểm chứng

| Hạng mục | Bằng chứng |
| --- | --- |
| Danh mục công ty/hợp đồng bảo hiểm | Migration V005, API và kiểm thử `0212608`; trạng thái xác minh độc lập với ngày hiệu lực, có nhân viên và ghi chú. |
| Database bảo hiểm cục bộ | V005 chạy hai lần; bảng, FK/check/index hiện diện; thử ghi/đọc trong transaction rồi rollback, không còn dữ liệu kiểm tra. |
| Thông báo khách hàng | Web/Mobile gọi API thật qua `117fb62`; V004 đã chạy trên SQL Server cục bộ, có 16 thông báo hiện hữu. |
| Backend | 398 test qua sau module bảo hiểm. |
| Web | `npx tsc --noEmit` và `npm run build` qua sau sửa lỗi báo cáo `3da8d9b`. |
| Mobile | `flutter analyze` không có lỗi; 27 test qua, gồm kiểm thử HTTP cho thông báo. |

## Chưa hoàn thành

1. Bảo hiểm: hồ sơ yêu cầu bồi thường, tài liệu và audit log, giám định hạng mục, báo giá nhiều phiên bản và duyệt từng dòng, liên kết kho, phân bổ hóa đơn/thanh toán, báo cáo, UI Web/Mobile. Module hiện tại **không** xác nhận bảo hiểm đã duyệt hoặc đã chuyển tiền.
2. Production mock: Dashboard, lịch hẹn, tiếp nhận, báo giá và một số trang công khai/khách hàng trên Web; lịch hẹn và báo giá Mobile. Danh sách từng file ở `INTEGRATION_AUDIT.md`.
3. Kiểm thử đầu cuối bằng tài khoản thật với API và SQL Server cho các màn Web/Mobile mới nối; xác nhận migration trên các môi trường khác.
4. Cleanup/refactor phần khác của dự án chưa được thực hiện; không xóa file hoặc sửa hàng loạt khi chưa xác minh dependency.

Checkout chính trên máy còn thay đổi chưa commit của người dùng/nhóm. Các commit trên được tạo từ checkout tạm sạch rồi push `integration`; chưa đồng bộ ngược vào checkout chính để tránh ghi đè dữ liệu.
