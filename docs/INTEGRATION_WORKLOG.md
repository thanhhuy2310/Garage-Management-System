# Nhật ký tích hợp

## 29/10/2026

- Kiểm tra nhánh local `integration`: working tree chính có nhiều thay đổi chưa commit, gồm file đã stage; giữ nguyên toàn bộ. Fetch remote và tạo checkout tạm sạch tại `334ca3f` để không trộn thay đổi của người khác.
- Chạy bộ kiểm thử Backend nền: 391 test qua.
- Kiểm tra các điểm dùng mock tại runtime của Web/Mobile; lập `INTEGRATION_AUDIT.md`.
- Bắt đầu Phase 5A: migration `V005__insurance_company_policy.sql`, API công ty/hợp đồng bảo hiểm và xác minh hợp đồng. Không suy diễn hiệu lực chỉ từ ngày và không tự cấp quyền phê duyệt bồi thường.
- Cập nhật thứ tự migration, gồm V004 thông báo mới từ remote. Bước 9–10 chưa được áp dụng hoặc xác minh trên database thật.
- Chạy V005 hai lần trên SQL Server cục bộ thành công. Thử ghi/đọc hợp đồng trong transaction rồi rollback; không còn bản ghi kiểm tra. Trạng thái áp dụng V004 thông báo trên database cục bộ vẫn cần kiểm tra riêng.
- Chạy lại toàn bộ kiểm thử Backend sau module bảo hiểm và kiểm thử phân quyền: 398 test qua, không có lỗi.
- Commit `0212608` (`feat(insurance): add company and policy foundation`) đã push lên `origin/integration`.

Các bước tiếp theo: hồ sơ bồi thường, nhật ký và tài liệu bảo mật; hạng mục giám định/báo giá phiên bản; kho và đối soát tiền; Web/Mobile; kiểm thử đầu cuối.
