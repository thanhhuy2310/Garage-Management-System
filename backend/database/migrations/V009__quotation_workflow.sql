-- Run after V008 with sqlcmd -I against the explicitly selected database.
-- BaoGia remains the current quotation (one per repair order). Each edit/decision
-- is preserved as an immutable JSON snapshot in LichSuBaoGia, including revisions.
-- No stock, invoice, existing quotation content or customer decision is rewritten.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET XACT_ABORT ON;
GO
IF COL_LENGTH('dbo.BaoGia','PhienBan') IS NULL
    ALTER TABLE dbo.BaoGia ADD PhienBan INT NOT NULL CONSTRAINT DF_BaoGia_PhienBan DEFAULT 0;
IF COL_LENGTH('dbo.BaoGia','LanDieuChinh') IS NULL
    ALTER TABLE dbo.BaoGia ADD LanDieuChinh INT NOT NULL CONSTRAINT DF_BaoGia_LanDieuChinh DEFAULT 1;
IF COL_LENGTH('dbo.BaoGia','MaNguoiLap') IS NULL
    ALTER TABLE dbo.BaoGia ADD MaNguoiLap INT NULL REFERENCES dbo.TaiKhoan(MaTaiKhoan);
IF COL_LENGTH('dbo.BaoGia','MaNguoiDuyet') IS NULL
    ALTER TABLE dbo.BaoGia ADD MaNguoiDuyet INT NULL REFERENCES dbo.TaiKhoan(MaTaiKhoan);
IF COL_LENGTH('dbo.BaoGia','NgayGui') IS NULL
    ALTER TABLE dbo.BaoGia ADD NgayGui DATETIME2(0) NULL;
IF COL_LENGTH('dbo.BaoGia','LyDoTuChoi') IS NULL
    ALTER TABLE dbo.BaoGia ADD LyDoTuChoi NVARCHAR(500) NULL;
GO
IF OBJECT_ID('dbo.LichSuBaoGia','U') IS NULL
BEGIN
    CREATE TABLE dbo.LichSuBaoGia (
        Id BIGINT IDENTITY(1,1) PRIMARY KEY,
        MaBaoGia INT NOT NULL REFERENCES dbo.BaoGia(MaBaoGia),
        PhienBan INT NOT NULL,
        LanDieuChinh INT NOT NULL,
        MaTaiKhoan INT NULL REFERENCES dbo.TaiKhoan(MaTaiKhoan),
        HanhDong NVARCHAR(40) NOT NULL,
        LyDo NVARCHAR(500) NULL,
        ThoiGian DATETIME2(0) NOT NULL CONSTRAINT DF_LichSuBaoGia_ThoiGian DEFAULT SYSDATETIME(),
        NoiDung NVARCHAR(MAX) NOT NULL,
        CONSTRAINT UQ_LichSuBaoGia_PhienBan UNIQUE(MaBaoGia,PhienBan),
        CONSTRAINT CK_LichSuBaoGia_Json CHECK(ISJSON(NoiDung)=1)
    );
END;
GO
-- Protect the historical manual warehouse procedure as well as the API. A
-- rejected confirmation rolls back its stock changes and the surrounding transaction.
CREATE OR ALTER TRIGGER dbo.TRG_ChiTietPhieuXuat_BaoGiaDaDuyet
ON dbo.ChiTietPhieuXuat
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted i
        LEFT JOIN deleted d ON d.MaPhieuXuat=i.MaPhieuXuat AND d.MaPhuTung=i.MaPhuTung
        JOIN dbo.PhieuXuatKho px ON px.MaPhieuXuat=i.MaPhieuXuat
        OUTER APPLY (
            SELECT SUM(CONVERT(BIGINT,q.SoLuong)) SoLuong,MIN(q.DonGia) GiaMin,MAX(q.DonGia) GiaMax
            FROM dbo.BaoGia b JOIN dbo.ChiTietBaoGia q ON q.MaBaoGia=b.MaBaoGia
            WHERE b.MaPhieuSuaChua=px.MaPhieuSuaChua AND b.TrangThai=N'DA_XAC_NHAN' AND q.MaPhuTung=i.MaPhuTung
        ) approved
        OUTER APPLY (
            SELECT COALESCE(SUM(CONVERT(BIGINT,ct.SoLuongThucDung)),0) SoLuong
            FROM dbo.ChiTietPhieuXuat ct JOIN dbo.PhieuXuatKho otherIssue ON otherIssue.MaPhieuXuat=ct.MaPhieuXuat
            WHERE otherIssue.MaPhieuSuaChua=px.MaPhieuSuaChua AND ct.MaPhuTung=i.MaPhuTung AND ct.DaXacNhanSuDung=1
        ) used
        WHERE i.DaXacNhanSuDung=1 AND i.SoLuongThucDung>0 AND COALESCE(d.DaXacNhanSuDung,0)=0
          AND (approved.SoLuong IS NULL OR used.SoLuong>approved.SoLuong OR i.DonGia IS NULL
               OR i.DonGia<>approved.GiaMin OR approved.GiaMin<>approved.GiaMax)
    ) THROW 50019,N'Phụ tùng thực dùng hoặc đơn giá/số lượng chưa được duyệt trong báo giá hiện hành.',1;
END;
GO
-- Rollback strategy: roll back application release while retaining added columns
-- and audit snapshots. Never delete accepted snapshots or run the base schema.
