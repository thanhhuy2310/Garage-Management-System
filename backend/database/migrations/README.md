<!-- TV3-TUAN8 -->
# Database migrations

Thứ tự setup database (bắt buộc đủ ba bước đầu, theo đúng thứ tự):

| Bước | File | Mục đích |
|---|---|---|
| 1 | `../QuanLyGaraOTo.sql` | Tạo database `QuanLyGaraOTo`, bảng, ràng buộc, procedure gốc và dữ liệu mẫu |
| 2 | `V001__add_customer_status.sql` | Thêm trạng thái khách hàng (`KhachHang.TrangThai`) |
| 3 | `V002__warehouse_actual_used_and_stock_check.sql` | Kho Tuần 8: thêm `ChiTietPhieuXuat.SoLuongThucDung`/`SoLuongHoanTra`, tạo `PhieuKiemKe`/`ChiTietKiemKe`, sửa `sp_XacNhanSuDungPhuTung` (trừ tồn theo số lượng **thực dùng**) và `sp_KiemKeTonKho` (chỉ ghi nhận kiểm kê, **không** tự đổi tồn; chỉ MANAGER duyệt qua ứng dụng) |
| 4 | `V003__confirm_usage_row_lock.sql` | Khóa dòng chi tiết phiếu xuất khi xác nhận thực dùng, chặn xác nhận trùng đồng thời trong procedure |
| tùy chọn | `../Test_Warehouse.sql` | Kiểm thử nghiệp vụ kho trên SQL Server (tự dọn dữ liệu test, in bảng PASS/FAIL) |
| tùy chọn | `../Test_Vehicles.sql`, `../Test_SpareParts.sql` | Kiểm thử ràng buộc xe / phụ tùng (tự ROLLBACK) |

Các migration đều idempotent (chạy lại không lỗi, không mất dữ liệu). Không có migration nào đổi tên bảng/cột hiện có.

Nếu chưa chạy V002, các API kho (`/api/warehouse/*`, `/api/inventory`) sẽ lỗi vì thiếu cột/bảng của Tuần 8.

## Kiểm tra thủ công chống xác nhận trùng đồng thời (SSMS, hai cửa sổ)

Test tự động của Java chỉ chứng minh API dùng khóa dòng (`PESSIMISTIC_WRITE`) và request thứ hai bị từ chối sau khi request đầu hoàn tất.
Việc hai request thực sự chạy song song cần SQL Server thật:

1. Tạo một chi tiết phiếu xuất chưa xác nhận (xem `Test_Warehouse.sql`, mục T5).
2. Cửa sổ A: `BEGIN TRAN; EXEC dbo.sp_XacNhanSuDungPhuTung @MaPhieuXuat, @MaPhuTung, @MaKyThuatVien, 3;` — **chưa COMMIT**.
3. Cửa sổ B: chạy đúng lệnh trên. B phải chờ A.
4. COMMIT ở A. B phải kết thúc với lỗi 50012 ("đã được xác nhận sử dụng"); tồn kho chỉ giảm 3 một lần và chỉ có một dòng `BienDongKho` loại `XUAT`.
