# Báo giá và phê duyệt

## Luồng và dữ liệu

`NHAP → CHO_XAC_NHAN → DA_XAC_NHAN / KHONG_DONG_Y`. Nhân viên tạo lần điều chỉnh từ báo giá đã gửi/đã phản hồi, ghi lý do, sửa bản nháp rồi gửi khách duyệt lại. `version` tăng theo mỗi lần ghi; `revision` tăng khi tạo lần điều chỉnh. Gửi lại quyết định giống nhau ở cùng phiên bản không tạo thêm lịch sử. Quyết định cũ không được áp dụng vào lần điều chỉnh mới.

Giữ `BaoGia` và `ChiTietBaoGia` làm báo giá hiện hành, một báo giá cho mỗi phiếu sửa chữa. `LichSuBaoGia` lưu toàn bộ nội dung từng phiên bản; API chỉ thêm snapshot, không sửa snapshot trước đó. Báo giá cũ được lưu snapshot trước thay đổi đầu tiên, không gán giả người đã duyệt trong quá khứ. Tiền dùng BigDecimal/DECIMAL; tổng và thành tiền do Backend/SQL tính. Client không gửi tổng tiền.

Khách chỉ đọc báo giá xe thuộc mình, không xem nháp và không thay nội dung. Lịch sử đã gửi vẫn được bảo toàn khi gara đang chuẩn bị điều chỉnh; danh sách khách chỉ hiện lại báo giá sau khi gửi. Nhân viên tiếp nhận và quản lý được lập/gửi/điều chỉnh; chỉ khách hàng chủ hồ sơ được quyết định.

## API

Tất cả endpoint có tiền tố `/api/quotations` và JWT. Response dùng envelope `ApiResponse` của project.

| Method | Path | Quyền | Nội dung |
|---|---|---|---|
| GET | `/` | CUSTOMER, RECEPTIONIST, MANAGER | Danh sách theo phạm vi truy cập |
| GET | `/{id}` | Như trên | Chi tiết và phiên bản hiện hành |
| GET | `/{id}/history` | Như trên | Snapshot; khách không thấy bản nháp |
| POST | `/` | RECEPTIONIST, MANAGER | `{repairOrderId, lines}`; trả 201 |
| PUT | `/{id}` | RECEPTIONIST, MANAGER | `{version, lines}`; chỉ sửa nháp |
| POST | `/{id}/send` | RECEPTIONIST, MANAGER | `{version, reason?}`; gửi thông báo thật |
| POST | `/{id}/revise` | RECEPTIONIST, MANAGER | `{version, reason}`; lý do bắt buộc |
| POST | `/{id}/decision` | CUSTOMER | `{version, accepted, reason?}` |

Mỗi dòng: `{kind: "SERVICE" | "PART", itemId, quantity, unitPrice?}`. Nếu không truyền giá thì dùng danh mục tại thời điểm lưu. Không trùng loại/mã; số lượng 1–100000; giá không âm và bắt buộc là bội số của 1.000đ; tối đa 100 dòng. Phiếu đã đóng hoặc có hóa đơn không được thay đổi báo giá. Xung đột phiên bản/trạng thái trả 409, sai dữ liệu trả 400, không đúng vai trò trả 403, không thuộc khách trả 404.

## Liên kết sửa chữa và kho

- Khóa phiếu sửa chữa trong transaction cho mọi thay đổi báo giá, quyết định và nghiệp vụ liên quan.
- Dịch vụ bắt đầu phải khớp dòng được duyệt về mã, số lượng và đơn giá. Chấp thuận đồng bộ dịch vụ chưa bắt đầu vào phiếu; dịch vụ đang thực hiện không được âm thầm thay giá/số lượng.
- Phụ tùng dự kiến chỉ ở báo giá, không trừ tồn. Cấp phát giữ đơn giá đã duyệt, kiểm tra tổng số đã dùng và đang cấp không vượt số được duyệt.
- Điều chỉnh phải giữ phụ tùng đã dùng và đang cấp phát. Có thể xác nhận hoàn trả toàn bộ phần chưa dùng trước khi giảm/bỏ số lượng đang cấp.
- Xác nhận thực dùng dương cần báo giá được duyệt; chỉ xác nhận thực dùng trừ kho. Trigger V009 kiểm tra cả đường gọi stored procedure cũ và hoàn tác giao dịch vi phạm.
- Snapshot, chi tiết sửa chữa và chi tiết xuất kho cho phép đối chiếu dự toán với thực tế. Luồng hóa đơn toàn hệ thống sẽ được nghiệm thu tiếp ở phase hồi quy/E2E.

## Migration và triển khai

Áp dụng `backend/database/migrations/V009__quotation_workflow.sql` sau V008 bằng `sqlcmd -I -b` vào database đã chọn rõ ràng. Migration chạy lại được, không tạo lại schema, không sửa quyết định hay tồn kho cũ. Đã kiểm tra trên `QuanLyGaraOTo_Verify_20261029`; chưa áp dụng database gara chính. Khi rollback ứng dụng, giữ cột bổ sung và lịch sử; không xóa snapshot.

## Kiểm thử tái lập

Backend: `mvnw.cmd test`. SQL Server: cấu hình datasource vào database Verify, đặt `RUN_SQLSERVER_IT=true`, chạy `mvnw.cmd -Dtest=QuotationsSqlServerIT test`. Tests từ chối database không đúng tiền tố và chỉ dọn ID tự tạo. Bảy ca SQL kiểm tra ownership, persistence/decimal, điều chỉnh, quyết định lặp/cạnh tranh, kho và stored procedure, đồng thời kiểm tra giá tròn nghìn và rollback khi nhập sai. Có 13 unit tests báo giá; đợt hồi quy 30/10/2026 có 431 tests qua.

Web: `npx tsc --noEmit`, `npm run build`. Flutter: `flutter analyze`, `flutter test`. `quotation_api_test.dart` dùng HTTP server cục bộ để kiểm tra adapter; không dùng kết quả này thay bằng chứng SQL/E2E.

Luồng UI thật dùng Backend Verify cổng 8088, Web 5188 và emulator `10.0.2.2:8088`. Fixture tài khoản được lưu riêng ngoài repo; không commit file credentials hay APK chứa dart-define kiểm thử. `Prepare_QuotationVerification.ps1` tạo tiếp nhận chuẩn bị bằng SQL (không tính là kiểm thử UI tiếp nhận), tạo phiếu và phụ tùng qua API.

Thứ tự bắt buộc, không chạy tất cả stage cùng lúc:

1. Chạy Web `quotations-live.spec.ts` với `--grep "quotation stage 1"`, biến `GARAGE_VERIFY_CREDENTIALS` trỏ file fixture: lập/gửi báo giá, kiểm tra SQL và giao diện khách.
2. Cập nhật `VERIFY_QUOTE_ID` trong file dart-define riêng từ `quoteId` của fixture. Chạy `flutter test integration_test/quotation_flow_test.dart -d emulator-5554 --dart-define-from-file=<private-file> --plain-name "quotation Android stage 1"`: khách từ chối và ghi lý do.
3. Chạy Web `--grep "quotation stage 2"`: thấy từ chối, điều chỉnh và gửi lại.
4. Chạy Android `--plain-name "quotation Android stage 2"`: khách xem tổng mới và chấp thuận.
5. Chạy Web `--grep "quotation stage 3"`: tải lại trạng thái đã duyệt, đối chiếu SQL, kiểm tra snapshot cũ và giao diện 1440/768/390.

Kết quả UI cụ thể, commit và phần chưa nghiệm thu được cập nhật trong `IMPLEMENTATION_PROGRESS.md`.

## Bổ sung yêu cầu giá — 30/10/2026

Người dùng xác nhận áp dụng giá tròn nghìn cho toàn bộ dịch vụ, phụ tùng và báo giá. PriceRules kiểm tra trước khi ghi ở danh mục, báo giá (kể cả giá lấy mặc định từ danh mục), chi tiết sửa chữa và nhập kho. Gửi bản nháp cũ có giá lẻ bị từ chối để nhân viên sửa rõ ràng. Không làm tròn âm thầm, không thay số tiền chứng từ/snapshot đã xác nhận. DECIMAL vẫn được giữ để đọc đúng dữ liệu lịch sử. Các bài kiểm thử UI mới dùng 150.000đ + 50.000đ, điều chỉnh thành 350.000đ.
