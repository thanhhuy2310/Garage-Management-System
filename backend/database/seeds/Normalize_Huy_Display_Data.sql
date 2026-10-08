-- Dọn nhãn hiển thị của bộ dữ liệu đã nạp. Không xóa phiếu, hóa đơn hay tài khoản.
-- Chạy sau migration V004. Có thể chạy lại; không đổi ID, mật khẩu, giá hoặc tiến độ.
USE QuanLyGaraOTo;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF COL_LENGTH(N'dbo.DichVu', N'TrangThai') IS NULL
    THROW 51000, N'Cần chạy V004__service_status.sql trước.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @LockResult INT;
    EXEC @LockResult = sys.sp_getapplock
        @Resource = N'garage-seed-huy-repair-billing-v1',
        @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
    IF @LockResult < 0 THROW 51001, N'Bộ dữ liệu đang được cập nhật ở phiên khác.', 1;

    DECLARE @DisplayPrefix NVARCHAR(30) = N'';
    DECLARE @LegacyPrefix NVARCHAR(30) = N'[TEST HUY] ';
    UPDATE dbo.KhachHang SET HoTen = STUFF(HoTen, 1, 11, N'')
    WHERE Email LIKE '%huy-test@example.test' AND LEFT(HoTen, 11) = @LegacyPrefix;
    DECLARE @Customers INT = @@ROWCOUNT;
    UPDATE dbo.KhachHang SET DiaChi = N'TP. Hồ Chí Minh'
    WHERE Email LIKE '%huy-test@example.test' AND DiaChi = N'TP. Hồ Chí Minh — dữ liệu kiểm thử của Huy';
    UPDATE dbo.NhanVien SET HoTen = STUFF(HoTen, 1, 11, N'')
    WHERE Email LIKE '%huy-test@example.test' AND LEFT(HoTen, 11) = @LegacyPrefix;
    DECLARE @Staff INT = @@ROWCOUNT;

    DECLARE @Services TABLE (Ten NVARCHAR(150), Loai NVARCHAR(100), MoTa NVARCHAR(500));
    INSERT INTO @Services VALUES
    (N'Kiểm tra tổng quát', N'Kiểm tra', N'Kiểm tra tình trạng vận hành và các hạng mục an toàn cơ bản của xe.'),
    (N'Thay dầu động cơ', N'Bảo dưỡng', N'Thay dầu phù hợp với động cơ và kiểm tra mức dầu sau khi thay.'),
    (N'Bảo dưỡng định kỳ', N'Bảo dưỡng', N'Kiểm tra và bảo dưỡng các hạng mục theo số km hoặc thời gian sử dụng.'),
    (N'Kiểm tra hệ thống phanh', N'Kiểm tra', N'Kiểm tra má phanh, đĩa phanh, dầu phanh và khả năng hoạt động của hệ thống.'),
    (N'Công thay má phanh', N'Sửa chữa', N'Thay má phanh và kiểm tra lại độ an toàn trước khi bàn giao xe.'),
    (N'Kiểm tra điều hòa', N'Kiểm tra', N'Kiểm tra khả năng làm lạnh, lưu lượng gió và tình trạng hệ thống điều hòa.'),
    (N'Vệ sinh dàn lạnh', N'Bảo dưỡng', N'Vệ sinh dàn lạnh, loại bỏ bụi bẩn và hạn chế mùi khó chịu trong xe.'),
    (N'Cân chỉnh thước lái', N'Sửa chữa', N'Kiểm tra và cân chỉnh góc đặt bánh xe để xe vận hành ổn định.'),
    (N'Đọc lỗi điện tử', N'Kiểm tra', N'Kết nối thiết bị chẩn đoán để đọc mã lỗi và kiểm tra hệ thống điện tử.'),
    (N'Kiểm tra sau bảo hành miễn phí', N'Kiểm tra', N'Kiểm tra lại hạng mục đã sửa chữa theo chính sách bảo hành của gara.');
    UPDATE @Services SET Ten = @DisplayPrefix + Ten;
    IF EXISTS (SELECT 1 FROM dbo.DichVu old JOIN @Services s
                   ON old.TenDichVu COLLATE Latin1_General_100_BIN2 = @LegacyPrefix + s.Ten
               JOIN dbo.DichVu currentService ON currentService.TenDichVu COLLATE Latin1_General_100_BIN2 = s.Ten)
        THROW 51002, N'Đã có dịch vụ cùng tên có dấu. Kiểm tra trước để tránh tạo trùng danh mục.', 1;
    UPDATE d SET TenDichVu = s.Ten,
        LoaiDichVu = CASE WHEN d.LoaiDichVu IN (N'KIEM_TRA', N'BAO_DUONG', N'SUA_CHUA') THEN s.Loai ELSE d.LoaiDichVu END,
        MoTa = CASE WHEN d.MoTa = N'Bộ kiểm thử sửa chữa và thanh toán của Huy.' THEN s.MoTa ELSE d.MoTa END
    FROM dbo.DichVu d JOIN @Services s ON d.TenDichVu COLLATE Latin1_General_100_BIN2 = @LegacyPrefix + s.Ten;
    DECLARE @RenamedServices INT = @@ROWCOUNT;

    -- Chỉ ngừng dùng đúng sáu tên không dấu cũ, không ảnh hưởng dịch vụ có dấu.
    UPDATE dbo.DichVu SET TrangThai = 0
    WHERE TrangThai = 1 AND TenDichVu COLLATE Latin1_General_100_BIN2 IN (
        N'Thay dau dong co', N'Bao duong dinh ky', N'Kiem tra he thong phanh',
        N'Thay ma phanh truoc', N'Ve sinh kim phun', N'Kiem tra dieu hoa');
    DECLARE @RetiredServices INT = @@ROWCOUNT;

    COMMIT TRANSACTION;
    SELECT @Customers AS KhachDaDoiTen, @Staff AS NhanVienDaDoiTen,
        @RenamedServices AS DichVuDaDoiTen, @RetiredServices AS DichVuNgungSuDung;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
