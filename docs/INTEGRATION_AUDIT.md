# Kiểm tra nhánh integration

Ngày kiểm tra: 29/10/2026. Mốc kiểm tra: `334ca3f` của `origin/integration`. Đây là danh sách phát hiện có thể tái kiểm tra từ source; trạng thái chỉ được đổi sau khi có kiểm thử tương ứng.

| Ưu tiên | Phát hiện và bằng chứng | Ảnh hưởng | Hướng xử lý | Trạng thái |
| --- | --- | --- | --- | --- |
| P0 | `frontend/src/pages/Dashboard.tsx`, `Appointments.tsx`, `Reception.tsx`, `Quotation.tsx` và nhiều trang khách hàng vẫn nhập `mock/data` hoặc `mock/schemaData`. | Màn hình có thể hiển thị số liệu không có trong SQL Server; thao tác nghiệp vụ không đồng bộ. | Đối chiếu từng API, bổ sung API còn thiếu, tích hợp loading/error/empty state, xác nhận bằng database thật. | Chưa xử lý |
| P0 | `mobile/lib/app/app.dart` vẫn khởi tạo `MockAppointmentService`, `MockQuotationService`. | Đặt lịch và báo giá trên mobile chưa phản ánh dữ liệu thực. | Kết nối các API có sẵn, bổ sung API thiếu và kiểm thử theo tài khoản khách hàng. | Chưa xử lý |
| P0 | Không có entity, migration hoặc API bảo hiểm tại mốc kiểm tra. | Không quản lý được hợp đồng/hồ sơ bồi thường và phân bổ công nợ. | Thực hiện theo `docs/INSURANCE_BUSINESS_WORKFLOW.md`, từng module có kiểm thử. | Đang xử lý: danh mục công ty/hợp đồng |
| P1 | `backend/database/migrations/README.md` thiếu `V004__customer_notifications_and_maintenance_reminders.sql`; các nhánh lịch sử dùng trùng số V002/V003/V004. | Dễ chạy migration sai hoặc bỏ sót khi triển khai. | Bổ sung thứ tự chạy thực tế, không đổi tên migration đã chia sẻ. | Đã cập nhật runbook |
| P1 | `frontend/src/main.tsx` chạy xác thực bộ mock khi khởi động. | Production còn phụ thuộc dữ liệu giả. | Loại bỏ sau khi các trang dùng dữ liệu thật. | Chưa xử lý; badge cố định đã bỏ |
| P1 | Trang thông báo khách hàng Web/Mobile từng dùng mock tại runtime. | Nội dung và trạng thái đã đọc không lưu database. | Nối API `/api/customers/me/notifications`, phân trang, cập nhật đã đọc và kiểm tra schema V004. | Đã xử lý trong `117fb62`; build/analyze/test qua |
| P1 | `mobile/lib/app/app.dart` còn điều hướng tới `feature_placeholder_screen.dart` cho một số tính năng. | Luồng khách hàng chưa hoàn chỉnh. | Xác minh route được dùng, thay bằng màn hình thực sau khi API sẵn sàng. | Chưa xử lý |
| P1 | `backend/src/main/resources/application.properties` từng có tên đăng nhập và mật khẩu SQL Server mặc định. | Môi trường cấu hình sai có thể vô tình sử dụng tài khoản mặc định. | Yêu cầu `DB_USERNAME`/`DB_PASSWORD` qua môi trường. | Đã xử lý; 398 test qua |
| P2 | `frontend/src/api/session.ts` dùng local/session storage cho phiên đăng nhập. | Phù hợp với session hiện tại; cần xem xét bảo mật token khi triển khai. | Giữ cho đến khi có phương án thay thế đồng bộ backend. | Ghi nhận |

## Phạm vi đã xác minh

- Backend: Java 21, Spring Boot, JPA, SQL Server; controller/service/repository/DTO và security hiện có. `mvn -B -o test` trên mốc `334ca3f`: 391 test qua, không có lỗi.
- Web: đã rà các điểm nhập dữ liệu giả và định tuyến. Các trang sửa chữa, kho, hóa đơn, báo cáo có API client, nhưng chưa kiểm chứng đầu cuối với database thật trong đợt kiểm tra này.
- Mobile: đã rà service được khởi tạo thực tế trong `app.dart`; các demo fixture riêng không bị coi là lỗi nếu không đi vào runtime.
- Database: đã rà schema, danh sách migration và runbook. Chưa xác nhận tương thích dữ liệu ở các môi trường khác máy phát triển.
- Database cục bộ: V005 đã chạy thành công hai lần trên `QuanLyGaraOTo`; đã kiểm tra bảng, bốn khóa ngoại, bốn ràng buộc kiểm tra và thử ghi/đọc trong transaction rồi rollback. Chưa kiểm tra trên môi trường khác.
- V004 thông báo được áp dụng trên database cục bộ sau khi xác nhận ban đầu còn thiếu. Truy vấn sau migration thấy 16 thông báo thật, gồm các khách hàng có số chưa đọc khác nhau. Chưa kiểm tra Web/Mobile đầu cuối với tài khoản đăng nhập thật.

## Tiêu chí trước khi đánh dấu hoàn thành

Mỗi chức năng cần có đường đi từ UI tới API và SQL Server, kiểm thử phân quyền, kiểm thử nghiệp vụ và thao tác đọc lại sau ghi. Không xóa fixture test, seed script có chủ đích hoặc stored procedure kho khi chưa chứng minh tương đương.
