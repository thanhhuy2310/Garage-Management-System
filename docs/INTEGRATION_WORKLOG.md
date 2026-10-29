# Nhật ký tích hợp

## 29/10/2026

- Kiểm tra nhánh local `integration`: working tree chính có nhiều thay đổi chưa commit, gồm file đã stage; giữ nguyên toàn bộ. Fetch remote và tạo checkout tạm sạch tại `334ca3f` để không trộn thay đổi của người khác.
- Chạy bộ kiểm thử Backend nền: 391 test qua.
- Kiểm tra các điểm dùng mock tại runtime của Web/Mobile; lập `INTEGRATION_AUDIT.md`.
- Bắt đầu Phase 5A: migration `V005__insurance_company_policy.sql`, API công ty/hợp đồng bảo hiểm và xác minh hợp đồng. Không suy diễn hiệu lực chỉ từ ngày và không tự cấp quyền phê duyệt bồi thường.
- Cập nhật thứ tự migration, gồm V004 thông báo mới từ remote. V004 và V005 đã áp dụng trên database phát triển cục bộ; môi trường khác vẫn phải kiểm tra riêng.
- Chạy V005 hai lần trên SQL Server cục bộ thành công. Thử ghi/đọc hợp đồng trong transaction rồi rollback; không còn bản ghi kiểm tra.
- Chạy lại toàn bộ kiểm thử Backend sau module bảo hiểm và kiểm thử phân quyền: 398 test qua, không có lỗi.
- Commit `0212608` (`feat(insurance): add company and policy foundation`) đã push lên `origin/integration`.
- Thay thông báo giả trên Web/Mobile bằng API thật, bổ sung xử lý tải/lỗi/trống, phân trang và thao tác đã đọc. Bỏ badge cố định trên thanh điều hướng nhân viên. Flutter analyze và 27 test qua; Vite build qua. Commit `117fb62` đã push.
- Phát hiện hai lỗi TypeScript ở `Reports.tsx` trước thay đổi thông báo; sửa tương thích ES2020 và kiểu formatter. `npx tsc --noEmit` và `npm run build` đều qua. Commit `3da8d9b` đã push.
- Áp dụng V004 thông báo trên SQL Server cục bộ sau khi thấy schema còn thiếu; truy vấn lại có 16 bản ghi `ThongBao` thật. Không tạo tài khoản hay thông báo mẫu mới.

Các bước tiếp theo: hồ sơ bồi thường, nhật ký và tài liệu bảo mật; hạng mục giám định/báo giá phiên bản; kho và đối soát tiền; Web/Mobile; kiểm thử đầu cuối.
