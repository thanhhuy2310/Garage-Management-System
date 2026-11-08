SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
BEGIN TRANSACTION;
IF COL_LENGTH('dbo.PhieuTiepNhan','MaKhachHangTiepNhan') IS NULL
BEGIN
    ALTER TABLE dbo.PhieuTiepNhan ADD MaKhachHangTiepNhan int NULL
        CONSTRAINT FK_TiepNhan_KhachTaiThoiDiemNhan REFERENCES dbo.KhachHang(MaKhachHang);
    -- Prefer a customer recorded on the transaction. For older walk-ins, retain
    -- the vehicle relationship that was used to authorize these records before migration.
    EXEC(N'UPDATE t SET MaKhachHangTiepNhan=COALESCE(a.MaKhachHang,h.MaKhachHang,x.MaKhachHang)
           FROM dbo.PhieuTiepNhan t JOIN dbo.Xe x ON x.MaXe=t.MaXe
           LEFT JOIN dbo.LichHen a ON a.MaLichHen=t.MaLichHen
           LEFT JOIN dbo.HoSoBaoHiem h ON h.MaTiepNhan=t.MaTiepNhan');
    EXEC(N'CREATE INDEX IX_TiepNhan_Khach_Xe ON dbo.PhieuTiepNhan(MaKhachHangTiepNhan,MaXe)');
END;
COMMIT;
