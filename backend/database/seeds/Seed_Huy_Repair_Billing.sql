-- DỮ LIỆU TEST LOCAL: dịch vụ, phân công KTV, sửa chữa, hóa đơn, Flutter theo dõi.
-- Chạy V001, V002, V003 trước. KHÔNG chạy trên database vận hành thật.
-- Tài khoản test_huy_* dùng mật khẩu demo123. Không có tài khoản ngân hàng giả.
-- Chỉ INSERT; không xóa, đổi mật khẩu hoặc đặt lại tiến độ khi chạy lại.
-- Chi tiết các ca thử và tài khoản: README.md trong cùng thư mục.
USE QuanLyGaraOTo;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.NhatKySuaChua', N'U') IS NULL
    OR OBJECT_ID(N'dbo.TaiKhoanNganHangGara', N'U') IS NULL
    OR COL_LENGTH(N'dbo.ThanhToan', N'MaYeuCau') IS NULL
    OR COL_LENGTH(N'dbo.KhachHang', N'TrangThai') IS NULL
    THROW 51000, N'Cần chạy migrations V001, V002, V003 trước khi thêm dữ liệu test.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @LockResult INT;
    EXEC @LockResult = sys.sp_getapplock
        @Resource = N'garage-seed-huy-repair-billing-v1',
        @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
    IF @LockResult < 0 THROW 51001, N'Bộ dữ liệu test đang được nạp ở phiên khác.', 1;

    DECLARE @Now DATETIME2(0) = SYSDATETIME();
    -- BCrypt của demo123, chỉ dùng cho các tài khoản TEST mới bên dưới.
    DECLARE @PasswordHash VARCHAR(255) = '$2a$10$cmQuil5sXrlLUZ540DVtcuEAIKD4PNfBsj9F0Z2iCby2wUQmaWppK';
    DECLARE @Customers TABLE (
        Stt INT PRIMARY KEY, HoTen NVARCHAR(100), DienThoai VARCHAR(20),
        Email VARCHAR(150), TenDangNhap VARCHAR(100), MaKhachHang INT
    );
    INSERT INTO @Customers (Stt, HoTen, DienThoai, Email, TenDangNhap) VALUES
    (1, N'[TEST HUY] Nguyễn Minh Huy', '0999700001', 'kh01.huy-test@example.test', 'test_huy_khach01'),
    (2, N'[TEST HUY] Trần Ngọc Anh',   '0999700002', 'kh02.huy-test@example.test', 'test_huy_khach02'),
    (3, N'[TEST HUY] Lê Hoàng Nam',    '0999700003', 'kh03.huy-test@example.test', 'test_huy_khach03'),
    (4, N'[TEST HUY] Phạm Thu Hà',     '0999700004', 'kh04.huy-test@example.test', 'test_huy_khach04'),
    (5, N'[TEST HUY] Võ Quốc Bảo',     '0999700005', 'kh05.huy-test@example.test', 'test_huy_khach05'),
    (6, N'[TEST HUY] Đặng Mỹ Linh',    '0999700006', 'kh06.huy-test@example.test', 'test_huy_khach06'),
    (7, N'[TEST HUY] Bùi Thanh Tùng',  '0999700007', 'kh07.huy-test@example.test', 'test_huy_khach07'),
    (8, N'[TEST HUY] Đỗ Khánh Vy',     '0999700008', 'kh08.huy-test@example.test', 'test_huy_khach08');

    -- Không gắn tài khoản test vào khách thật nếu số điện thoại vô tình bị trùng.
    IF EXISTS (SELECT 1 FROM @Customers s JOIN dbo.KhachHang k ON k.SoDienThoai = s.DienThoai
               WHERE ISNULL(k.Email, '') <> s.Email)
        THROW 51002, N'Số điện thoại test trùng khách khác. Dừng để bảo vệ dữ liệu.', 1;
    INSERT INTO dbo.KhachHang (HoTen, SoDienThoai, Email, DiaChi, TrangThai)
    SELECT s.HoTen, s.DienThoai, s.Email, N'TP. Hồ Chí Minh — dữ liệu kiểm thử của Huy', 1
    FROM @Customers s WHERE NOT EXISTS (SELECT 1 FROM dbo.KhachHang k WHERE k.SoDienThoai = s.DienThoai);
    UPDATE s SET MaKhachHang = k.MaKhachHang
    FROM @Customers s JOIN dbo.KhachHang k ON k.SoDienThoai = s.DienThoai;

    DECLARE @Staff TABLE (
        Stt INT PRIMARY KEY, HoTen NVARCHAR(100), DienThoai VARCHAR(20), Email VARCHAR(150),
        ChucVu NVARCHAR(100), TenDangNhap VARCHAR(100), VaiTro NVARCHAR(50), MaNhanVien INT
    );
    INSERT INTO @Staff (Stt, HoTen, DienThoai, Email, ChucVu, TenDangNhap, VaiTro) VALUES
    (1, N'[TEST HUY] Quản lý', '0999700101', 'manager.huy-test@example.test', N'QUAN_LY', 'test_huy_manager', N'MANAGER'),
    (2, N'[TEST HUY] Tiếp nhận', '0999700102', 'reception.huy-test@example.test', N'NHAN_VIEN_TIEP_NHAN', 'test_huy_tiepnhan', N'RECEPTIONIST'),
    (3, N'[TEST HUY] KTV Minh', '0999700103', 'ktv01.huy-test@example.test', N'KY_THUAT_VIEN', 'test_huy_ktv01', N'TECHNICIAN'),
    (4, N'[TEST HUY] KTV Phúc', '0999700104', 'ktv02.huy-test@example.test', N'KY_THUAT_VIEN', 'test_huy_ktv02', N'TECHNICIAN');
    IF EXISTS (SELECT s.Email FROM @Staff s JOIN dbo.NhanVien n ON n.Email = s.Email
               GROUP BY s.Email HAVING COUNT(*) > 1)
        THROW 51003, N'Email nhân viên test bị trùng nhiều bản ghi. Cần kiểm tra trước.', 1;
    INSERT INTO dbo.NhanVien (HoTen, SoDienThoai, Email, ChucVu)
    SELECT s.HoTen, s.DienThoai, s.Email, s.ChucVu FROM @Staff s
    WHERE NOT EXISTS (SELECT 1 FROM dbo.NhanVien n WHERE n.Email = s.Email);
    UPDATE s SET MaNhanVien = n.MaNhanVien FROM @Staff s JOIN dbo.NhanVien n ON n.Email = s.Email;
    INSERT INTO dbo.KyThuatVien (MaNhanVien)
    SELECT s.MaNhanVien FROM @Staff s WHERE s.VaiTro = N'TECHNICIAN'
        AND NOT EXISTS (SELECT 1 FROM dbo.KyThuatVien k WHERE k.MaNhanVien = s.MaNhanVien);

    IF EXISTS (SELECT 1 FROM @Customers s JOIN dbo.TaiKhoan a ON a.TenDangNhap = s.TenDangNhap
               WHERE ISNULL(a.MaKhachHang, -1) <> s.MaKhachHang OR a.VaiTro <> N'CUSTOMER')
        OR EXISTS (SELECT 1 FROM @Staff s JOIN dbo.TaiKhoan a ON a.TenDangNhap = s.TenDangNhap
                   WHERE ISNULL(a.MaNhanVien, -1) <> s.MaNhanVien OR a.VaiTro <> s.VaiTro)
        THROW 51004, N'Tên tài khoản test đang thuộc người hoặc vai trò khác. Không ghi đè.', 1;
    INSERT INTO dbo.TaiKhoan (TenDangNhap, MatKhauHash, VaiTro, TrangThai, MaKhachHang, MaNhanVien)
    SELECT s.TenDangNhap, @PasswordHash, N'CUSTOMER', 1, s.MaKhachHang, NULL FROM @Customers s
    WHERE NOT EXISTS (SELECT 1 FROM dbo.TaiKhoan a WHERE a.TenDangNhap = s.TenDangNhap)
    UNION ALL
    SELECT s.TenDangNhap, @PasswordHash, s.VaiTro, 1, NULL, s.MaNhanVien FROM @Staff s
    WHERE NOT EXISTS (SELECT 1 FROM dbo.TaiKhoan a WHERE a.TenDangNhap = s.TenDangNhap);

    DECLARE @Services TABLE (Stt INT PRIMARY KEY, Ten NVARCHAR(150), Loai NVARCHAR(100), Gia DECIMAL(18,2), MaDichVu INT);
    INSERT INTO @Services (Stt, Ten, Loai, Gia) VALUES
    (1, N'[TEST HUY] Kiểm tra tổng quát', N'KIEM_TRA', 150000),
    (2, N'[TEST HUY] Thay dầu động cơ', N'BAO_DUONG', 350000),
    (3, N'[TEST HUY] Bảo dưỡng định kỳ', N'BAO_DUONG', 600000),
    (4, N'[TEST HUY] Kiểm tra hệ thống phanh', N'KIEM_TRA', 250000),
    (5, N'[TEST HUY] Công thay má phanh', N'SUA_CHUA', 450000),
    (6, N'[TEST HUY] Kiểm tra điều hòa', N'KIEM_TRA', 200000),
    (7, N'[TEST HUY] Vệ sinh dàn lạnh', N'BAO_DUONG', 500000),
    (8, N'[TEST HUY] Cân chỉnh thước lái', N'SUA_CHUA', 400000),
    (9, N'[TEST HUY] Đọc lỗi điện tử', N'KIEM_TRA', 220000),
    (10, N'[TEST HUY] Kiểm tra sau bảo hành miễn phí', N'KIEM_TRA', 0);
    IF EXISTS (SELECT s.Ten FROM @Services s JOIN dbo.DichVu d ON d.TenDichVu = s.Ten GROUP BY s.Ten HAVING COUNT(*) > 1)
        THROW 51005, N'Tên dịch vụ test trùng nhiều bản ghi. Cần kiểm tra trước.', 1;
    INSERT INTO dbo.DichVu (TenDichVu, LoaiDichVu, DonGia, MoTa)
    SELECT s.Ten, s.Loai, s.Gia, N'Bộ kiểm thử sửa chữa và thanh toán của Huy.' FROM @Services s
    WHERE NOT EXISTS (SELECT 1 FROM dbo.DichVu d WHERE d.TenDichVu = s.Ten);
    UPDATE s SET MaDichVu = d.MaDichVu FROM @Services s JOIN dbo.DichVu d ON d.TenDichVu = s.Ten;

    -- Mỗi ca có một biển số riêng. Tám ca đầu cố ý CHƯA có phiếu sửa chữa.
    DECLARE @Cases TABLE (
        Stt INT PRIMARY KEY, MoTa NVARCHAR(200), TrangThai NVARCHAR(50), Ktv INT NULL,
        CoHoaDon BIT NOT NULL, BienSo VARCHAR(20), MaKhachHang INT, MaXe INT,
        MocTiepNhan DATETIME2(0), MaTiepNhan INT
    );
    INSERT INTO @Cases (Stt, MoTa, TrangThai, Ktv, CoHoaDon) VALUES
    (1, N'Chờ lập phiếu — kiểm tra tổng quát', NULL, NULL, 0),
    (2, N'Chờ lập phiếu — thay dầu', NULL, NULL, 0),
    (3, N'Chờ lập phiếu — bảo dưỡng', NULL, NULL, 0),
    (4, N'Chờ lập phiếu — phanh kêu', NULL, NULL, 0),
    (5, N'Chờ lập phiếu — điều hòa yếu', NULL, NULL, 0),
    (6, N'Chờ lập phiếu — lệch thước lái', NULL, NULL, 0),
    (7, N'Chờ lập phiếu — đèn báo động cơ', NULL, NULL, 0),
    (8, N'Chờ lập phiếu — vệ sinh dàn lạnh', NULL, NULL, 0),
    (9, N'Phiếu mới, chưa phân công', N'MOI_TAO', NULL, 0),
    (10, N'Phiếu mới để bổ sung dịch vụ và phân công', N'MOI_TAO', NULL, 0),
    (11, N'Kỹ thuật viên đang kiểm tra', N'DANG_KIEM_TRA', 3, 0),
    (12, N'Đã kiểm tra, chờ bắt đầu sửa', N'CHO_SUA', 4, 0),
    (13, N'Đang sửa, còn dịch vụ chưa bắt đầu', N'DANG_SUA', 3, 0),
    (14, N'Đang sửa, đã hoàn tất một dịch vụ', N'DANG_SUA', 4, 0),
    (15, N'Hai kỹ thuật viên cùng được phân công', N'DANG_SUA', 3, 0),
    (16, N'Tạm dừng chờ phụ tùng', N'CHO_PHU_TUNG', 3, 0),
    (17, N'Chờ phụ tùng, có thể tiếp tục sửa', N'CHO_PHU_TUNG', 4, 0),
    (18, N'Hoàn tất, chờ lập hóa đơn', N'HOAN_TAT', 3, 0),
    (19, N'Hoàn tất kiểm tra miễn phí, chờ lập hóa đơn 0 đồng', N'HOAN_TAT', 4, 0),
    (20, N'Hóa đơn chưa thanh toán', N'HOAN_TAT', 3, 1),
    (21, N'Hóa đơn đã thanh toán một phần', N'HOAN_TAT', 4, 1),
    (22, N'Hóa đơn đã thu đủ tiền mặt', N'HOAN_TAT', 3, 1),
    (23, N'Hóa đơn đã thu đủ qua hai lần thanh toán', N'HOAN_TAT', 4, 1),
    (24, N'Phiếu đã hủy — chỉ xem lịch sử', N'HUY', 3, 0);
    UPDATE c SET BienSo = '51H-990.' + RIGHT('0' + CONVERT(VARCHAR(2), c.Stt), 2),
        MaKhachHang = k.MaKhachHang,
        MocTiepNhan = CASE WHEN c.Stt <= 8 THEN DATEADD(MINUTE, -15 * c.Stt, @Now)
                          ELSE DATEADD(HOUR, 3 * c.Stt, DATEADD(DAY, -7, @Now)) END
    FROM @Cases c JOIN @Customers k ON k.Stt = ((c.Stt - 1) % 8) + 1;
    IF EXISTS (SELECT 1 FROM @Cases c JOIN dbo.Xe x ON x.BienSo = c.BienSo WHERE x.MaKhachHang <> c.MaKhachHang)
        THROW 51006, N'Biển số test đang thuộc khách khác. Không thay đổi xe hiện có.', 1;
    INSERT INTO dbo.Xe (MaKhachHang, BienSo, HangXe, DongXe, NamSanXuat, SoKm)
    SELECT c.MaKhachHang, c.BienSo,
        CASE c.Stt % 4 WHEN 0 THEN N'Toyota' WHEN 1 THEN N'Honda' WHEN 2 THEN N'Mazda' ELSE N'Kia' END,
        CASE c.Stt % 4 WHEN 0 THEN N'Vios' WHEN 1 THEN N'City' WHEN 2 THEN N'Mazda 3' ELSE N'Seltos' END,
        2020 + c.Stt % 5, 15000 + c.Stt * 1700
    FROM @Cases c WHERE NOT EXISTS (SELECT 1 FROM dbo.Xe x WHERE x.BienSo = c.BienSo);
    UPDATE c SET MaXe = x.MaXe FROM @Cases c JOIN dbo.Xe x ON x.BienSo = c.BienSo;

    -- GhiChu là mã ca ổn định, không dựa vào IDENTITY hoặc thứ tự dữ liệu có sẵn.
    IF EXISTS (SELECT t.GhiChu FROM dbo.PhieuTiepNhan t JOIN @Cases c
                   ON t.GhiChu = N'HUY-TEST-V1-' + RIGHT('0' + CONVERT(VARCHAR(2), c.Stt), 2)
               GROUP BY t.GhiChu HAVING COUNT(*) > 1)
        THROW 51007, N'Mã ca tiếp nhận test đã bị trùng. Cần kiểm tra trước.', 1;
    IF EXISTS (SELECT 1 FROM dbo.PhieuTiepNhan t JOIN @Cases c
                   ON t.GhiChu = N'HUY-TEST-V1-' + RIGHT('0' + CONVERT(VARCHAR(2), c.Stt), 2)
               WHERE t.MaXe <> c.MaXe)
        THROW 51008, N'Mã ca test đang gắn với xe khác. Không ghi đè.', 1;
    DECLARE @NewReceptions TABLE (Id INT);
    INSERT INTO dbo.PhieuTiepNhan (MaXe, NgayTiepNhan, TinhTrangBanDau, YeuCauKhachHang, GhiChu)
    OUTPUT inserted.MaTiepNhan INTO @NewReceptions
    SELECT c.MaXe, c.MocTiepNhan, N'Xe vận hành được, cần kiểm tra theo yêu cầu của khách.', c.MoTa,
           N'HUY-TEST-V1-' + RIGHT('0' + CONVERT(VARCHAR(2), c.Stt), 2)
    FROM @Cases c WHERE NOT EXISTS (SELECT 1 FROM dbo.PhieuTiepNhan t
        WHERE t.GhiChu = N'HUY-TEST-V1-' + RIGHT('0' + CONVERT(VARCHAR(2), c.Stt), 2));
    UPDATE c SET MaTiepNhan = t.MaTiepNhan, MocTiepNhan = t.NgayTiepNhan
    FROM @Cases c JOIN dbo.PhieuTiepNhan t
        ON t.GhiChu = N'HUY-TEST-V1-' + RIGHT('0' + CONVERT(VARCHAR(2), c.Stt), 2);

    -- Chỉ thêm chi tiết/nhật ký/hóa đơn cho phiếu VỪA tạo ở lần chạy này.
    -- Phiếu đã được bạn sửa, thanh toán hoặc lập từ 8 ca trống được giữ nguyên.
    DECLARE @NewOrders TABLE (Id INT, MaTiepNhan INT);
    INSERT INTO dbo.PhieuSuaChua (MaTiepNhan, NgayLap, NgayBatDau, NgayHoanThanh, TrangThai, KetQua)
    OUTPUT inserted.MaPhieuSuaChua, inserted.MaTiepNhan INTO @NewOrders
    SELECT c.MaTiepNhan, DATEADD(MINUTE, 10, c.MocTiepNhan),
        CASE WHEN c.TrangThai IN (N'DANG_SUA', N'CHO_PHU_TUNG', N'HOAN_TAT') THEN DATEADD(MINUTE, 40, c.MocTiepNhan) END,
        CASE WHEN c.TrangThai = N'HOAN_TAT' THEN DATEADD(MINUTE, 150, c.MocTiepNhan) END,
        c.TrangThai, CASE WHEN c.TrangThai = N'HOAN_TAT' THEN N'Đã hoàn tất các hạng mục, kiểm tra xe trước khi bàn giao.' END
    FROM @Cases c WHERE c.TrangThai IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM dbo.PhieuSuaChua p WHERE p.MaTiepNhan = c.MaTiepNhan);

    INSERT INTO dbo.PhanCongKyThuatVien (MaPhieuSuaChua, MaKyThuatVien, NgayPhanCong, GhiChu)
    SELECT n.Id, s.MaNhanVien, DATEADD(MINUTE, 15, c.MocTiepNhan), N'Thực hiện dịch vụ và cập nhật tiến độ cho khách.'
    FROM @NewOrders n JOIN @Cases c ON c.MaTiepNhan = n.MaTiepNhan
    JOIN @Staff s ON s.Stt = c.Ktv OR (c.Stt = 15 AND s.Stt = 4);

    DECLARE @Lines TABLE (OrderId INT, ServiceId INT, ThuTu INT, TrangThai NVARCHAR(50), PRIMARY KEY (OrderId, ServiceId));
    INSERT INTO @Lines (OrderId, ServiceId, ThuTu, TrangThai)
    SELECT n.Id, s.MaDichVu, v.ThuTu,
        CASE WHEN c.TrangThai = N'HOAN_TAT' THEN N'HOAN_TAT'
             WHEN c.TrangThai IN (N'DANG_SUA', N'CHO_PHU_TUNG') AND c.Stt <> 13 AND v.ThuTu = 1 THEN N'HOAN_TAT'
             WHEN c.TrangThai = N'DANG_SUA' AND (c.Stt <> 13 OR v.ThuTu = 1) THEN N'DANG_SUA'
             ELSE N'CHO_SUA' END
    FROM @NewOrders n JOIN @Cases c ON c.MaTiepNhan = n.MaTiepNhan
    CROSS JOIN (VALUES (1), (2)) v(ThuTu)
    JOIN @Services s ON s.Stt = CASE WHEN c.Stt = 19 THEN 10 ELSE ((c.Stt + v.ThuTu - 2) % 9) + 1 END
    WHERE c.Stt <> 19 OR v.ThuTu = 1;
    INSERT INTO dbo.ChiTietDichVu (MaPhieuSuaChua, MaDichVu, SoLuong, DonGia, TrangThai)
    SELECT l.OrderId, l.ServiceId, CASE WHEN c.Stt = 21 AND l.ThuTu = 2 THEN 2 ELSE 1 END, d.DonGia, l.TrangThai
    FROM @Lines l JOIN dbo.DichVu d ON d.MaDichVu = l.ServiceId
    JOIN @NewOrders n ON n.Id = l.OrderId JOIN @Cases c ON c.MaTiepNhan = n.MaTiepNhan;

    INSERT INTO dbo.NhatKySuaChua (MaPhieuSuaChua, MaDichVu, TrangThai, NoiDung, NguoiCapNhat, ThoiGian)
    SELECT n.Id, NULL, N'MOI_TAO', N'Đã lập phiếu, chờ phân công kỹ thuật viên.', 'test_huy_tiepnhan', DATEADD(MINUTE, 10, c.MocTiepNhan)
    FROM @NewOrders n JOIN @Cases c ON c.MaTiepNhan = n.MaTiepNhan;
    INSERT INTO dbo.NhatKySuaChua (MaPhieuSuaChua, MaDichVu, TrangThai, NoiDung, NguoiCapNhat, ThoiGian)
    SELECT n.Id, NULL, v.TrangThai, v.NoiDung, s.TenDangNhap, DATEADD(MINUTE, v.Phut, c.MocTiepNhan)
    FROM @NewOrders n JOIN @Cases c ON c.MaTiepNhan = n.MaTiepNhan JOIN @Staff s ON s.Stt = c.Ktv
    CROSS JOIN (VALUES
        (20, N'DANG_KIEM_TRA', N'Đang kiểm tra tình trạng xe và các hạng mục khách yêu cầu.'),
        (30, N'CHO_SUA', N'Đã kiểm tra, chuẩn bị thực hiện các dịch vụ trên phiếu.'),
        (40, N'DANG_SUA', N'Bắt đầu thực hiện sửa chữa.'),
        (120, N'CHO_PHU_TUNG', N'Tạm dừng, chờ đủ phụ tùng để tiếp tục công việc.'),
        (150, N'HOAN_TAT', N'Đã hoàn tất các hạng mục, kiểm tra xe trước khi bàn giao.'),
        (35, N'HUY', N'Khách chưa thực hiện sửa chữa, phiếu được đóng.')) v(Phut, TrangThai, NoiDung)
    WHERE (v.Phut = 20 AND c.TrangThai NOT IN (N'MOI_TAO', N'HUY'))
       OR (v.Phut = 30 AND c.TrangThai IN (N'CHO_SUA', N'DANG_SUA', N'CHO_PHU_TUNG', N'HOAN_TAT'))
       OR (v.Phut = 40 AND c.TrangThai IN (N'DANG_SUA', N'CHO_PHU_TUNG', N'HOAN_TAT'))
       OR (v.Phut = 120 AND c.TrangThai = N'CHO_PHU_TUNG')
       OR (v.Phut = 150 AND c.TrangThai = N'HOAN_TAT')
       OR (v.Phut = 35 AND c.TrangThai = N'HUY');
    INSERT INTO dbo.NhatKySuaChua (MaPhieuSuaChua, MaDichVu, TrangThai, NoiDung, NguoiCapNhat, ThoiGian)
    SELECT l.OrderId, l.ServiceId, v.TrangThai, v.NoiDung, s.TenDangNhap,
        DATEADD(MINUTE, v.Phut + l.ThuTu * 10, c.MocTiepNhan)
    FROM @Lines l JOIN @NewOrders n ON n.Id = l.OrderId JOIN @Cases c ON c.MaTiepNhan = n.MaTiepNhan
    JOIN @Staff s ON s.Stt = c.Ktv
    CROSS JOIN (VALUES (40, N'DANG_SUA', N'Bắt đầu thực hiện dịch vụ.'), (80, N'HOAN_TAT', N'Đã thực hiện và kiểm tra lại dịch vụ.')) v(Phut, TrangThai, NoiDung)
    WHERE (v.TrangThai = N'DANG_SUA' AND l.TrangThai IN (N'DANG_SUA', N'HOAN_TAT'))
       OR (v.TrangThai = N'HOAN_TAT' AND l.TrangThai = N'HOAN_TAT');

    DECLARE @NewInvoices TABLE (Id INT, OrderId INT);
    INSERT INTO dbo.HoaDon (MaPhieuSuaChua, NgayLap, TongTien, TrangThai)
    OUTPUT inserted.MaHoaDon, inserted.MaPhieuSuaChua INTO @NewInvoices
    SELECT n.Id, DATEADD(MINUTE, 160, c.MocTiepNhan), SUM(d.SoLuong * d.DonGia),
        CASE WHEN c.Stt >= 22 THEN N'DA_THANH_TOAN' ELSE N'CHUA_THANH_TOAN' END
    FROM @NewOrders n JOIN @Cases c ON c.MaTiepNhan = n.MaTiepNhan
    JOIN dbo.ChiTietDichVu d ON d.MaPhieuSuaChua = n.Id
    WHERE c.CoHoaDon = 1 GROUP BY n.Id, c.MocTiepNhan, c.Stt;
    -- Các khoản thu sau chỉ là lịch sử thanh toán TEST, không phải chuyển tiền thật.
    INSERT INTO dbo.ThanhToan (MaHoaDon, NgayThanhToan, SoTien, PhuongThuc, MaYeuCau)
    SELECT h.MaHoaDon, DATEADD(MINUTE, v.Phut, c.MocTiepNhan),
        CASE WHEN c.Stt = 21 THEN ROUND(h.TongTien * 0.4, 0)
             WHEN c.Stt = 22 THEN h.TongTien
             WHEN v.Lan = 1 THEN ROUND(h.TongTien / 2, 0)
             ELSE h.TongTien - ROUND(h.TongTien / 2, 0) END,
        CASE WHEN v.Lan = 2 OR c.Stt = 21 THEN N'CHUYEN_KHOAN' ELSE N'TIEN_MAT' END,
        CONVERT(VARCHAR(36), NEWID())
    FROM @NewInvoices i JOIN dbo.HoaDon h ON h.MaHoaDon = i.Id
    JOIN @NewOrders n ON n.Id = i.OrderId JOIN @Cases c ON c.MaTiepNhan = n.MaTiepNhan
    CROSS JOIN (VALUES (1, 170), (2, 200)) v(Lan, Phut)
    WHERE c.Stt IN (21, 22, 23) AND (v.Lan = 1 OR c.Stt = 23);

    IF EXISTS (SELECT 1 FROM @NewInvoices i JOIN dbo.HoaDon h ON h.MaHoaDon = i.Id
        OUTER APPLY (SELECT COALESCE(SUM(SoTien), 0) DaTra FROM dbo.ThanhToan WHERE MaHoaDon = i.Id) p
        WHERE p.DaTra > h.TongTien OR (h.TrangThai = N'DA_THANH_TOAN' AND p.DaTra <> h.TongTien))
        THROW 51009, N'Tổng thanh toán test không khớp hóa đơn. Hủy toàn bộ lần thêm.', 1;

    COMMIT TRANSACTION;

    SELECT (SELECT COUNT(*) FROM @NewReceptions) AS SoTiepNhanVuaThem,
           (SELECT COUNT(*) FROM @NewOrders) AS SoPhieuSuaChuaVuaThem,
           (SELECT COUNT(*) FROM @NewInvoices) AS SoHoaDonVuaThem;
    SELECT c.Stt AS CaTest, c.MoTa, c.BienSo, k.TenDangNhap AS KhachDangNhap,
        c.MaTiepNhan, p.MaPhieuSuaChua, p.TrangThai, h.MaHoaDon, h.TongTien,
        COALESCE(pay.DaTra, 0) AS DaThanhToan, h.TongTien - COALESCE(pay.DaTra, 0) AS ConLai
    FROM @Cases c JOIN @Customers k ON k.MaKhachHang = c.MaKhachHang
    LEFT JOIN dbo.PhieuSuaChua p ON p.MaTiepNhan = c.MaTiepNhan
    LEFT JOIN dbo.HoaDon h ON h.MaPhieuSuaChua = p.MaPhieuSuaChua
    OUTER APPLY (SELECT SUM(SoTien) DaTra FROM dbo.ThanhToan WHERE MaHoaDon = h.MaHoaDon) pay
    ORDER BY c.Stt;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
