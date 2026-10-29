# Quy trình bảo hiểm vật chất xe

## Ranh giới nghiệp vụ

Hợp đồng bảo hiểm vật chất xe được ghi nhận độc lập với bảo hiểm trách nhiệm dân sự và bảo hành sửa chữa. Ngày hiệu lực chỉ là một điều kiện; nhân viên phải đối chiếu chứng nhận và các điều khoản rồi ghi trạng thái xác minh. Mức miễn thường, khấu hao, quyền chọn gara và phạm vi phụ tùng lấy từ từng hợp đồng/hồ sơ, không dùng tỷ lệ chung.

## Luồng dự kiến

1. Nhân viên tiếp nhận xe, tạo phiếu tiếp nhận và gắn hợp đồng đã khai báo. Kiểm tra chủ xe, công ty, loại bảo hiểm, thời hạn, tình trạng xác minh và chứng từ.
2. Tạo hồ sơ tổn thất với mã duy nhất; lưu thời điểm/sự kiện, thông báo công ty bảo hiểm, giấy tờ, ảnh và người phụ trách. Trùng cùng tổn thất phải được phát hiện trước khi ghi nhận khoản phải thu.
3. Ghi từng hạng mục giám định, kể cả hạng mục bổ sung sau tháo kiểm. Kết quả giám định cũ được giữ để đối chiếu.
4. Lập báo giá theo phiên bản. Lưu riêng giá trị đề nghị, giá trị được bảo hiểm chấp thuận, phần khách trả và lý do giảm trừ cho từng dòng. Kết quả bên bảo hiểm phải có bằng chứng và nhân viên ghi nhận; tài khoản gara không đóng vai bên bảo hiểm.
5. Chỉ sau khi có quyền sửa chữa phù hợp mới lập yêu cầu cấp phát. Xuất kho và xác nhận thực dùng theo procedure hiện có; báo giá hoặc phê duyệt bảo hiểm không tự trừ kho.
6. Lập hóa đơn từ chi phí thực tế, tính phần bảo hiểm và khách hàng bằng `BigDecimal`, đối soát tổng phân bổ. Theo dõi riêng bảo hiểm đã duyệt và tiền thực nhận. Nếu khách ứng trước và là người thụ hưởng hoàn trả, gara không ghi khoản phải thu từ doanh nghiệp bảo hiểm.
7. Khóa hồ sơ khi hoàn tất nhưng vẫn giữ lịch sử, phiên bản báo giá, chứng từ và audit log.

## Trạng thái triển khai

Hiện chỉ có bước nền về danh mục công ty và hợp đồng. API xác minh hợp đồng yêu cầu người ghi nhận và ghi chú, và không cho ghi đè kết quả cũ. Hồ sơ bồi thường, giám định, báo giá phiên bản, kho, thanh toán và màn hình chưa được triển khai; không sử dụng danh mục mới để suy ra bảo hiểm đã duyệt hay đã thanh toán.

Tài liệu tham khảo quy tắc bảo hiểm: [BSH](https://bshc.com.vn/doanh-nghiep/bao-hiem-vat-chat-xe-o-to), [PVI](https://online.pvi.com.vn/tai-lieu-va-quy-tac).
