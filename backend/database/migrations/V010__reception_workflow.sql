-- Additive, rerunnable migration; preserves every existing reception and repair order.
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO
IF COL_LENGTH('dbo.PhieuTiepNhan','MaLichHen') IS NULL
    ALTER TABLE dbo.PhieuTiepNhan ADD MaLichHen INT NULL REFERENCES dbo.LichHen(MaLichHen);
IF COL_LENGTH('dbo.PhieuTiepNhan','SoKmTiepNhan') IS NULL
    ALTER TABLE dbo.PhieuTiepNhan ADD SoKmTiepNhan INT NULL CHECK (SoKmTiepNhan>=0);
IF COL_LENGTH('dbo.PhieuTiepNhan','MaNhanVienTiepNhan') IS NULL
    ALTER TABLE dbo.PhieuTiepNhan ADD MaNhanVienTiepNhan INT NULL REFERENCES dbo.NhanVien(MaNhanVien);
IF COL_LENGTH('dbo.PhieuTiepNhan','NgayCapNhat') IS NULL
    ALTER TABLE dbo.PhieuTiepNhan ADD NgayCapNhat DATETIME2(0) NULL;
IF COL_LENGTH('dbo.PhieuTiepNhan','PhienBan') IS NULL
    ALTER TABLE dbo.PhieuTiepNhan ADD PhienBan INT NOT NULL CONSTRAINT DF_PhieuTiepNhan_PhienBan DEFAULT 0;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='UX_PhieuTiepNhan_LichHen' AND object_id=OBJECT_ID('dbo.PhieuTiepNhan'))
    CREATE UNIQUE INDEX UX_PhieuTiepNhan_LichHen ON dbo.PhieuTiepNhan(MaLichHen) WHERE MaLichHen IS NOT NULL;
GO
