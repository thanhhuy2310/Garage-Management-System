-- Stores the existing public contact form; rerunnable and does not alter historical records.
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO
IF OBJECT_ID('dbo.LienHeKhachHang','U') IS NULL
BEGIN
    CREATE TABLE dbo.LienHeKhachHang (
        MaLienHe INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        MaYeuCau VARCHAR(36) NOT NULL CONSTRAINT UQ_LienHeKhachHang_YeuCau UNIQUE,
        HoTen NVARCHAR(100) NOT NULL,
        SoDienThoai NVARCHAR(20) NOT NULL,
        BienSo NVARCHAR(20) NULL,
        NoiDung NVARCHAR(2000) NOT NULL,
        NgayGui DATETIME2(0) NOT NULL,
        DaDoc BIT NOT NULL CONSTRAINT DF_LienHeKhachHang_DaDoc DEFAULT 0
    );
END;
GO
