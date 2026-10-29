-- Chay thu cong sau V007; khong tao/xoa database, khong sua lich hen cu.
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
BEGIN TRANSACTION;
IF COL_LENGTH('dbo.LichHen', 'PhienBan') IS NULL
    ALTER TABLE dbo.LichHen ADD PhienBan INT NOT NULL CONSTRAINT DF_LichHen_PhienBan DEFAULT 0;
IF COL_LENGTH('dbo.LichHen', 'NgayTao') IS NULL
    ALTER TABLE dbo.LichHen ADD NgayTao DATETIME2(0) NULL, NgayCapNhat DATETIME2(0) NULL;
IF OBJECT_ID('dbo.KhungGioTiepNhan', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.KhungGioTiepNhan (
        Thu INT NOT NULL, -- ISO: 1 = Monday, 7 = Sunday
        Gio TIME(0) NOT NULL,
        SucChua INT NOT NULL,
        MaTaiKhoanCapNhat INT NOT NULL REFERENCES dbo.TaiKhoan(MaTaiKhoan),
        NgayCapNhat DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT PK_KhungGioTiepNhan PRIMARY KEY (Thu, Gio),
        CONSTRAINT CK_KhungGio_Thu CHECK (Thu BETWEEN 1 AND 7),
        CONSTRAINT CK_KhungGio_SucChua CHECK (SucChua >= 0),
        CONSTRAINT CK_KhungGio_Phut CHECK (DATEPART(SECOND, Gio) = 0)
    );
END;
IF OBJECT_ID('dbo.LichSuLichHen', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.LichSuLichHen (
        Id BIGINT IDENTITY PRIMARY KEY,
        MaLichHen INT NOT NULL REFERENCES dbo.LichHen(MaLichHen),
        MaTaiKhoan INT NOT NULL REFERENCES dbo.TaiKhoan(MaTaiKhoan),
        HanhDong NVARCHAR(30) NOT NULL,
        NgayHen DATE NOT NULL, GioHen TIME(0) NOT NULL,
        TrangThai NVARCHAR(50) NOT NULL,
        PhienBan INT NOT NULL,
        LyDo NVARCHAR(500) NULL,
        ThoiGian DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT UQ_LichSuLichHen_PhienBan UNIQUE (MaLichHen, PhienBan)
    );
END;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.LichHen') AND name='IX_LichHen_Slot')
    CREATE INDEX IX_LichHen_Slot ON dbo.LichHen(NgayHen, GioHen, TrangThai) INCLUDE(MaXe);
COMMIT;
-- Khong seed khung gio: quan ly cau hinh bang API/Web theo nang luc thuc te.
-- Rollback: quay lai code cu truoc, giu cac cot/bang bo sung de bao toan audit.
-- Chi drop schema bo sung neu da backup va xac nhan chua co du lieu moi.
