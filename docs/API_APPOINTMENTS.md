# Lịch hẹn — API và kiểm chứng

Triển khai Spring Boot/SQL Server. Áp dụng V008 theo `backend/database/migrations/README.md` trước khi chạy. Không seed khung giờ; quản lý nhập năng lực tiếp nhận thật trên Web → Lịch hẹn → Cấu hình khung giờ. Sức chứa tính theo thời điểm tiếp nhận, không phải thời lượng sửa chữa.

| Endpoint | Quyền | Nội dung |
|---|---|---|
| GET /api/appointments | CUSTOMER, RECEPTIONIST, MANAGER | Khách chỉ nhận lịch của mình; nhân viên nhận danh sách gara |
| GET /api/appointments/{id} | Như trên + ownership | Chi tiết và version |
| GET /api/appointments/{id}/history | Như trên + ownership | Actor, thời điểm, phiên bản, trạng thái và lịch sau thay đổi |
| GET /api/appointments/availability?date=yyyy-MM-dd | Như trên | Khung giờ cấu hình, sức chứa và chỗ còn; giờ Việt Nam |
| GET /api/appointments/schedule | MANAGER | Cấu hình theo thứ ISO 1–7 |
| PUT /api/appointments/schedule | MANAGER | {dayOfWeek,time,capacity}; 0 đóng nhận mới, giữ lịch cũ |
| POST /api/appointments | CUSTOMER, RECEPTIONIST, MANAGER | {vehicleId,serviceId?,date,time,note?}; trả 201 sau khi lưu |
| PATCH /api/appointments/{id}/confirm | RECEPTIONIST, MANAGER | {version,reason?} |
| PATCH /api/appointments/{id}/cancel | CUSTOMER, RECEPTIONIST, MANAGER + ownership | {version,reason?}; không xóa lịch |
| PATCH /api/appointments/{id}/reschedule | Như trên | {version,date,time,reason?}; quay về CHO_XAC_NHAN |

Client không gửi customerId hoặc trạng thái khi tạo; server lấy chủ xe và đối chiếu JWT. Lịch đã tiếp nhận/hủy/hoàn tất không được dời. Xác nhận/hủy lặp không sinh audit hoặc thông báo trùng. Đổi từ phiên bản cũ trả 409. Hai yêu cầu tranh chỗ cuối được tuần tự hóa bằng SQL application lock thuộc transaction; kiểm tra sức chứa, trùng xe, ghi lịch, trigger thông báo và audit cùng commit/rollback.

ADMIN chỉ quản trị tài khoản theo policy hiện có, không tham gia lịch hẹn. Không nới quyền toàn hệ thống để phục vụ màn này.

## Kiểm chứng

- `mvnw.cmd test`: unit/API regression; `AppointmentServiceTest` có 11 ca mới.
- SQL thật: `RUN_SQLSERVER_IT=true`, cấu hình datasource trỏ database có tiền tố `QuanLyGaraOTo_Verify_`, chạy `mvnw.cmd -Dtest=AppointmentsSqlServerIT test`. Test từ chối database khác, tạo fixture riêng và chỉ dọn các ID do test tạo.
- Database mới: `backend/database/Initialize_VerificationDatabase.ps1` (từ chối nếu database đã tồn tại).
- Web/Flutter: chạy backend trên 8088 với database Verify, rồi `Prepare_VerificationAccounts.ps1`. File credentials ở TEMP, không commit.
- `GARAGE_VERIFY_CREDENTIALS=<file TEMP>`; Web chạy `npx playwright test --config=playwright.live.config.ts --grep 'create on customer'`.
- Android: `integration_test/appointment_flow_test.dart`, dùng `--dart-define-from-file` trỏ file ngoài repo gồm API_BASE_URL, VERIFY_USERNAME, VERIFY_PASSWORD, VERIFY_BOOKING_ID, VERIFY_NEW_TIME. Emulator gọi `http://10.0.2.2:8088/api`. Test đăng nhập và thao tác UI thật.
- Sau Android, chạy Web `--grep 'reload Web'` để kiểm tra đồng bộ và SQL.
- `mobile/test/appointment_sql_live_test.dart` là kiểm tra adapter HTTP thật thay thế khi không có thiết bị, không phải bằng chứng UI Android. Không chạy cùng Android trên một booking đã bị hủy.

Tiếp nhận và quan hệ lịch hẹn → phiếu tiếp nhận được tích hợp ở phase D; không cho client đổi tùy ý thành đã đến/hoàn tất.
