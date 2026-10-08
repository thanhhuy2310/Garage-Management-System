# Dữ liệu để Huy test phần sửa chữa và thanh toán

File cần chạy: `Seed_Huy_Repair_Billing.sql`.

Bộ này thêm dữ liệu vào SQL thật để web và Flutter gọi API lấy lên. Không thêm mock vào code giao diện. Tên khách, nhân viên và dịch vụ có tiền tố `[TEST HUY]` để phân biệt với dữ liệu khác. Đây vẫn là dữ liệu giả lập để thử chức năng, không phải giao dịch kinh doanh thật.

## Cách nạp

1. Dùng database local `QuanLyGaraOTo`, chạy migrations V001, V002, V003 nếu chưa chạy.
2. Mở file seed trong SSMS và chạy cả file. **Không chạy lại `QuanLyGaraOTo.sql` trên database đã có dữ liệu.**
3. Bảng kết quả cuối file cho biết mã phiếu và hóa đơn của từng ca. ID được SQL tự cấp, không cố định là 1, 2, 3.
4. Tải lại trang web. Đăng nhập tài khoản test tương ứng khi kiểm tra phân quyền hoặc mobile.

Lần đầu thêm 8 khách, 4 nhân viên (2 KTV), 12 tài khoản, 10 dịch vụ, 24 xe, 24 phiếu tiếp nhận, 16 phiếu sửa chữa, 4 hóa đơn và 4 lần thanh toán. Có nhật ký từng dịch vụ và thông báo hoàn tất từ trigger.

Chạy lại không thêm trùng, không đưa phiếu đã sửa về trạng thái ban đầu, không đặt lại mật khẩu hay các khoản đã thu. Nếu bạn đã dùng một phiếu tiếp nhận để lập sửa chữa thì nó không tự trở về danh sách chờ khi chạy lại. Không đổi mã `HUY-TEST-V1-xx` trong ghi chú tiếp nhận nếu còn muốn chạy lại bộ này.

Script chỉ thêm bản ghi mới vào các bảng nghiệp vụ, không DELETE/UPDATE dữ liệu cũ, không tắt khóa ngoại, không đặt lại IDENTITY. Nếu gặp trùng số điện thoại/biển số/tài khoản với người khác, script dừng và rollback thay vì gắn nhầm dữ liệu.

## Tài khoản

Mật khẩu ban đầu của tất cả tài khoản dưới đây: **`demo123`**. Chỉ dùng trên máy local, không đưa bộ tài khoản này lên môi trường thật.

| Đăng nhập | Dùng để test |
| --- | --- |
| `test_huy_manager` | Dịch vụ, lập phiếu, phân công KTV, tiến độ, hóa đơn, ngân hàng |
| `test_huy_tiepnhan` | Lập phiếu sửa chữa, xem phiếu và thu tiền; không được phân công/cập nhật tiến độ |
| `test_huy_ktv01` | Công việc của KTV Minh |
| `test_huy_ktv02` | Công việc của KTV Phúc; có một phiếu chung với Minh |
| `test_huy_khach01` … `test_huy_khach08` | Đăng nhập Flutter để xem tiến độ và lịch sử của chính khách đó |

Ví dụ dùng **`test_huy_khach05`** trên Flutter: có xe `51H-990.13` đang sửa và xe `51H-990.21` đã hoàn tất. Khách 06/07 cũng có cả phiếu đang sửa và đã hoàn tất. Khách 08 có phiếu chờ phụ tùng và phiếu hủy.

## Chọn dữ liệu nào để thử?

Hai chữ số cuối biển số tương ứng với số ca. Ví dụ ca 13 là xe `51H-990.13`.

| Ca | Dữ liệu ban đầu | Thao tác nên thử |
| --- | --- | --- |
| 01–08 | Đã tiếp nhận, chưa có phiếu sửa chữa | Mở **Lập phiếu sửa chữa**, chọn xe và dịch vụ. Lưu rồi tải lại; xe vừa chọn phải biến mất khỏi danh sách chờ |
| 09–10 | Mới tạo, chưa có KTV | Bổ sung dịch vụ, phân công KTV; thử phân công trùng |
| 11 | Đang kiểm tra | Chuyển sang chờ sửa hoặc đang sửa |
| 12 | Chờ sửa | Bắt đầu sửa chữa |
| 13 | Đang sửa, dịch vụ thứ hai chưa bắt đầu | Thử hoàn tất phiếu sớm phải bị từ chối; hoàn tất lần lượt từng dịch vụ |
| 14 | Đang sửa, một dịch vụ xong | KTV Phúc cập nhật; KTV Minh không được xem phiếu này |
| 15 | Hai KTV cùng được phân công | Cả hai được xem; khi một người lưu trước, người còn lại phải tải lại nếu gửi trạng thái cũ |
| 16–17 | Chờ phụ tùng | Chuyển lại đang sửa trước khi cập nhật dịch vụ |
| 18 | Hoàn tất, chưa có hóa đơn | Lập hóa đơn; thử lập lần hai phải bị từ chối |
| 19 | Dịch vụ miễn phí, chưa có hóa đơn | Lập hóa đơn 0 đồng; không cần thu tiền |
| 20 | Hóa đơn chưa thu | Thu một phần, thu tiếp phần còn lại; kiểm tra số dư sau tải lại |
| 21 | Đã thu 40% | Thu phần còn lại; thử nhập vượt số còn phải thu |
| 22 | Đã thu đủ tiền mặt | Xem lịch sử; không còn nút thu thêm |
| 23 | Thu đủ qua hai lần: tiền mặt và chuyển khoản | Xem hai khoản thu và đối chiếu tổng tiền |
| 24 | Đã hủy | Xem lịch sử Flutter và kiểm tra không có nút sửa/phân công; hiện chưa có thao tác hủy phiếu trên web |

Hóa đơn mới trong bộ này tính theo công dịch vụ, có ca số lượng 2 và ca miễn phí. Không thêm/xuất phụ tùng, không thay đổi tồn kho. Các hóa đơn cũ có phụ tùng trong file SQL gốc được giữ nguyên.

Không tạo số tài khoản ngân hàng giả để tránh quét QR chuyển nhầm. Muốn test QR, đăng nhập quản lý → **Hóa đơn → Tài khoản ngân hàng**, nhập thông tin tài khoản thật. Các khoản chuyển khoản trong ca 21/23 chỉ là lịch sử test, không phát sinh giao dịch tại ngân hàng.

## Kiểm tra script trước khi nạp

Tại thư mục `backend`:

```powershell
.\mvnw.cmd "-Dtest=SeedDataSqlServerIT" test
```

Test dùng SQL Server cấu hình trong `.env`, tạo dữ liệu với tên/biển số QA riêng rồi rollback. Nó thử chạy script nhiều lần, đăng nhập, phân quyền KTV/khách, tạo phiếu, cập nhật dịch vụ, thu thêm tiền và lập hóa đơn miễn phí. IDENTITY có thể tăng sau test; các khoảng trống ID là bình thường.

File SQL gốc đã đổi trạng thái mẫu `DANG_THUC_HIEN` thành `DANG_SUA` cho lần khởi tạo database mới, khớp API hiện tại. Script này không tự đổi trạng thái của những phiếu cũ đã tồn tại.
