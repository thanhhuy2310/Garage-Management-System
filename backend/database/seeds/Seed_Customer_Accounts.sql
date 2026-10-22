-- Tài khoản bổ sung cho ba khách hàng có sẵn trong dữ liệu ban đầu.
-- Mật khẩu ban đầu: Gara@123456 (chỉ dùng ở môi trường phát triển; đổi sau khi đăng nhập).
-- Có thể chạy lại. Không đổi tài khoản, mật khẩu hoặc thông tin khách hàng đã có.
USE QuanLyGaraOTo;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Customers TABLE (HoTen NVARCHAR(150), DienThoai VARCHAR(20), TenDangNhap VARCHAR(100));
    INSERT INTO @Customers VALUES
        (N'Tran Minh Tuan', '0900000002', 'tranminhtuan'),
        (N'Le Hoang Nam', '0900000003', 'lehoangnam'),
        (N'Pham Ngoc Lan', '0900000004', 'phamngoclan');

    IF EXISTS (SELECT 1 FROM @Customers s LEFT JOIN dbo.KhachHang k WITH (UPDLOCK, HOLDLOCK)
                   ON k.SoDienThoai = s.DienThoai
               WHERE k.MaKhachHang IS NULL OR k.HoTen COLLATE Latin1_General_100_CI_AI <> s.HoTen OR k.TrangThai = 0)
        THROW 51000, N'Khách hàng không khớp tên, số điện thoại hoặc đã ngừng hoạt động. Chưa tạo tài khoản.', 1;

    IF EXISTS (SELECT 1 FROM @Customers s JOIN dbo.KhachHang k ON k.SoDienThoai = s.DienThoai
               JOIN dbo.TaiKhoan a WITH (UPDLOCK, HOLDLOCK) ON a.TenDangNhap = s.TenDangNhap
               WHERE ISNULL(a.MaKhachHang, -1) <> k.MaKhachHang OR a.VaiTro <> N'CUSTOMER')
        THROW 51001, N'Tên đăng nhập đã được dùng cho tài khoản khác. Chưa tạo tài khoản.', 1;

    DECLARE @Created TABLE (TenDangNhap VARCHAR(100), MaKhachHang INT);
    INSERT INTO dbo.TaiKhoan (TenDangNhap, MatKhauHash, VaiTro, TrangThai, MaKhachHang, MaNhanVien)
        OUTPUT inserted.TenDangNhap, inserted.MaKhachHang INTO @Created
    SELECT s.TenDangNhap, '$2a$10$vBzoP4iDXwlZ..6/snjK1.kH2LiYZbe8OLuakO9D4ARCcXNF1VqDC',
           N'CUSTOMER', 1, k.MaKhachHang, NULL
    FROM @Customers s JOIN dbo.KhachHang k ON k.SoDienThoai = s.DienThoai
    WHERE NOT EXISTS (SELECT 1 FROM dbo.TaiKhoan a WITH (UPDLOCK, HOLDLOCK) WHERE a.MaKhachHang = k.MaKhachHang);

    COMMIT TRANSACTION;
    SELECT a.TenDangNhap, k.HoTen FROM @Created a JOIN dbo.KhachHang k ON k.MaKhachHang = a.MaKhachHang;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
