# Quy trình bảo hiểm vật chất xe

## Ranh giới nghiệp vụ

Hợp đồng bảo hiểm vật chất xe được ghi nhận độc lập với bảo hiểm trách nhiệm dân sự và bảo hành sửa chữa. Ngày hiệu lực chỉ là một điều kiện; nhân viên phải đối chiếu chứng nhận và các điều khoản rồi ghi trạng thái xác minh. Mức miễn thường, khấu hao, quyền chọn gara và phạm vi phụ tùng lấy từ từng hợp đồng/hồ sơ, không dùng tỷ lệ chung.

Theo quy tắc nghiệp vụ của dự án, người đứng tên hợp đồng phải là chủ xe gắn với `Xe.MaKhachHang`. Nhân viên nhập tên chủ xe trên giấy đăng ký và trên giấy chứng nhận bảo hiểm; hệ thống so khớp hai tên với tên khách hàng sau khi chuẩn hóa khoảng trắng/chữ hoa. Tên khớp chỉ cho phép tiếp tục xác minh, không tự chuyển hợp đồng sang `DA_XAC_MINH`. Hợp đồng cũ thiếu hai tên không thể được xác minh cho đến khi có quy trình bổ sung thông tin. Giấy chứng nhận TNDS bắt buộc phải có tên chủ xe theo Điều 10 Nghị định 67/2023/NĐ-CP; [giải thích của Bộ Tài chính](https://baochinhphu.vn/sang-ten-xe-bao-hiem-trach-nhiem-dan-su-cu-co-con-hieu-luc-102251010102858317.htm) cũng lưu ý xử lý khi chuyển quyền sở hữu xe.

## Luồng dự kiến

1. Nhân viên tiếp nhận xe, tạo phiếu tiếp nhận và gắn hợp đồng đã khai báo. Kiểm tra chủ xe, công ty, loại bảo hiểm, thời hạn, tình trạng xác minh và chứng từ.
2. Tạo hồ sơ tổn thất với mã duy nhất; lưu thời điểm/sự kiện, thông báo công ty bảo hiểm, giấy tờ, ảnh và người phụ trách. Trùng cùng tổn thất phải được phát hiện trước khi ghi nhận khoản phải thu.
3. Ghi từng hạng mục giám định, kể cả hạng mục bổ sung sau tháo kiểm. Kết quả giám định cũ được giữ để đối chiếu.
4. Lập báo giá theo phiên bản. Lưu riêng giá trị đề nghị, giá trị được bảo hiểm chấp thuận, phần khách trả và lý do giảm trừ cho từng dòng. Kết quả bên bảo hiểm phải có bằng chứng và nhân viên ghi nhận; tài khoản gara không đóng vai bên bảo hiểm.
5. Chỉ sau khi có quyền sửa chữa phù hợp mới lập yêu cầu cấp phát. Xuất kho và xác nhận thực dùng theo procedure hiện có; báo giá hoặc phê duyệt bảo hiểm không tự trừ kho.
6. Lập hóa đơn từ chi phí thực tế, tính phần bảo hiểm và khách hàng bằng `BigDecimal`, đối soát tổng phân bổ. Theo dõi riêng bảo hiểm đã duyệt và tiền thực nhận. Nếu khách ứng trước và là người thụ hưởng hoàn trả, gara không ghi khoản phải thu từ doanh nghiệp bảo hiểm.
7. Khóa hồ sơ khi hoàn tất nhưng vẫn giữ lịch sử, phiên bản báo giá, chứng từ và audit log.

## Trạng thái triển khai

Đã có danh mục công ty, hợp đồng và bước tạo/đọc hồ sơ tổn thất. API xác minh hợp đồng yêu cầu nhân viên và ghi chú, không cho ghi đè kết quả cũ. Hồ sơ gắn với phiếu tiếp nhận, chặn trùng cùng phiếu hoặc cùng xe/thời điểm/địa điểm, và ghi sự kiện tạo hồ sơ trong cùng transaction. Chặn trùng tự động không thay thế việc nhân viên đối chiếu sự cố gần giống nhau.

Giám định, tài liệu chứng minh, thay đổi trạng thái hồ sơ, báo giá phiên bản, kho, thanh toán và màn hình chưa được triển khai. Trạng thái `MOI_TAO` không có nghĩa bảo hiểm đã chấp thuận hoặc đã chuyển tiền.

Tài liệu tham khảo quy tắc bảo hiểm: [BSH](https://bshc.com.vn/doanh-nghiep/bao-hiem-vat-chat-xe-o-to), [PVI](https://online.pvi.com.vn/tai-lieu-va-quy-tac).
