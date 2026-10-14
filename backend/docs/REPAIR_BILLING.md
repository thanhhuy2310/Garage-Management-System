# Sửa chữa, tiến độ và thu tiền

Trước khi chạy backend, chạy migration V002 rồi V003 trên database gara. Không cần import lại dữ liệu.

## Thử trên giao diện

1. Lễ tân hoặc quản lý mở **Phiếu sửa chữa → Lập phiếu sửa chữa**, chọn một phiếu tiếp nhận và dịch vụ. Có thể bổ sung dịch vụ trước khi bắt đầu sửa. Giá được lưu theo thời điểm thêm dịch vụ.
2. Quản lý/admin phân công kỹ thuật viên. KTV đăng nhập vào **Công việc của tôi**, mở phiếu được giao.
3. Bấm **Cập nhật tiến độ** để bắt đầu. Mỗi dịch vụ lần lượt chuyển từ chờ thực hiện sang đang thực hiện rồi hoàn tất. Nhập nội dung công việc mỗi lần cập nhật.
4. Khi tất cả dịch vụ xong, hoàn tất phiếu và ghi kết quả sửa chữa. Phiếu đã kết thúc hoặc có hóa đơn không được thay đổi nữa.
5. Lễ tân/quản lý/admin mở **Hóa đơn → Lập hóa đơn**, chọn phiếu hoàn tất. Tổng tiền lấy từ dịch vụ và phụ tùng trên phiếu, không lấy từ báo giá mẫu.
6. Chọn **Ghi nhận thanh toán**, nhập số tiền đã nhận. Có thể thu nhiều lần; không được thu vượt số còn lại. Chỉ xác nhận sau khi đã nhận tiền mặt hoặc đối chiếu giao dịch ngân hàng.
7. Khách đăng nhập trên Flutter, mở tab **Theo dõi**. Kéo xuống để tải lại. Khi trở lại tab hoặc mở lại ứng dụng, tiến độ cũng được làm mới. Tab **Đã kết thúc** hiển thị lịch sử.

Nhật ký cũ chưa tồn tại sẽ hiện trống; ứng dụng không tự tạo các mốc sửa chữa giả. Khách chỉ thấy xe thuộc tài khoản của mình.

## Chuyển khoản và QR

Quản lý/admin vào **Hóa đơn → Tài khoản ngân hàng** để thêm nhiều tài khoản nhận tiền. Lễ tân chỉ được chọn tài khoản đang sử dụng. Danh sách ngân hàng có MB, Vietcombank, BIDV, Techcombank, ACB và một số ngân hàng khác; mã BIN đối chiếu theo [danh mục VietQR](https://api.vietqr.io/v2/banks).

Không có số tài khoản mẫu. Tên mặc định là `GARA O TO THANH CONG`, cần sửa thành đúng tên đã đăng ký ở ngân hàng trước khi dùng. Khi chưa cấu hình tài khoản, vẫn ghi nhận được khoản chuyển tiền đã đối chiếu, nhưng không hiện QR.

QR điền sẵn ngân hàng, số tài khoản, số tiền nguyên đồng và nội dung hóa đơn. Phiên hiển thị kéo dài 15 phút rồi ẩn mã và cho tạo lại. Đây không phải lệnh thanh toán có hạn do ngân hàng phát hành: ảnh QR đã lưu vẫn có thể chuyển được. Chưa có webhook ngân hàng nên quét QR không tự chuyển hóa đơn sang đã thanh toán.

## Một số API cần dùng

Lập phiếu: `POST /api/repair-orders`

```json
{"receptionId": 10, "services": [{"serviceId": 2, "quantity": 1}]}
```

Cập nhật phiếu: `PUT /api/repair-orders/{id}/progress`. Cập nhật dịch vụ dùng cùng nội dung tại `/{id}/services/{serviceId}/progress`.

```json
{"expectedStatus": "CHO_SUA", "status": "DANG_SUA", "notes": "Bắt đầu kiểm tra phanh."}
```

`expectedStatus` là trạng thái đang hiển thị. Nếu người khác vừa sửa, API trả 409 để tải lại, không ghi đè. KTV không được sửa phiếu chưa phân công cho mình. Lễ tân không được cập nhật tiến độ.

Lập hóa đơn: `POST /api/invoices` với `{"repairOrderId": 10}`.

Thu tiền: `POST /api/invoices/{id}/payments`

```json
{
  "amount": 100000,
  "method": "TIEN_MAT",
  "requestId": "dd976269-e1d4-489a-96be-751beb420599",
  "bankAccountId": null
}
```

Dùng `CHUYEN_KHOAN` khi chuyển khoản, kèm mã tài khoản nhận nếu đã chọn. Mỗi giao dịch mới cần UUID mới; khi gửi lại do mất kết nối phải giữ nguyên UUID và nội dung. Backend khóa hóa đơn trong lúc tính số tiền còn lại và ghi nhận để tránh thu vượt; mã yêu cầu có unique index trong SQL.

## Kiểm tra

- `mvnw.cmd test`: kiểm tra quyền, chuyển trạng thái, tính tiền, gửi trùng, cấu hình ngân hàng trên database H2 riêng cho test.
- `mvnw.cmd "-Dtest=SqlServerApiIT,RepairBillingSqlServerIT" test`: kiểm tra schema, trigger, nhật ký, hóa đơn và thanh toán trên SQL Server cấu hình trong `.env`. Dùng database phát triển; test rollback dữ liệu, identity có thể tăng.
- `frontend`: `npm run test:e2e`, `npm run build`, `npx tsc --noEmit`.
- `mobile`: `flutter analyze`, `flutter test`.

Dữ liệu giả trong test chỉ phục vụ kiểm thử, không chạy trong các màn sửa chữa, hóa đơn và theo dõi đã nối API. Các phần đặt lịch, kho, báo giá, trang tổng quan chưa được chuyển hết sang backend trong đợt này.
