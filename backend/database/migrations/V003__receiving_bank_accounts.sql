-- Không thêm số tài khoản mẫu. Quản lý cấu hình tài khoản thật trên web.
IF OBJECT_ID(N'dbo.TaiKhoanNganHangGara', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TaiKhoanNganHangGara (
        MaTaiKhoan INT IDENTITY(1,1) PRIMARY KEY,
        TenNganHang NVARCHAR(100) NOT NULL,
        MaNganHang VARCHAR(6) NOT NULL,
        SoTaiKhoan VARCHAR(25) NOT NULL,
        ChuTaiKhoan NVARCHAR(100) NOT NULL,
        DangSuDung BIT NOT NULL DEFAULT 1,
        CONSTRAINT UQ_TaiKhoanGara_NganHang_So UNIQUE (MaNganHang, SoTaiKhoan)
    );
END;
GO
IF COL_LENGTH(N'dbo.ThanhToan', N'MaTaiKhoanNhan') IS NULL
    ALTER TABLE dbo.ThanhToan ADD MaTaiKhoanNhan INT NULL
        CONSTRAINT FK_ThanhToan_TaiKhoanNhan REFERENCES dbo.TaiKhoanNganHangGara(MaTaiKhoan);
GO
