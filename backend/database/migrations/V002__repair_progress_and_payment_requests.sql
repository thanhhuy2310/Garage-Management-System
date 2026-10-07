-- Chạy một lần trên database gara hiện tại. Không xóa hoặc thay thế dữ liệu.
IF OBJECT_ID(N'dbo.NhatKySuaChua', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.NhatKySuaChua (
        MaNhatKy BIGINT IDENTITY(1,1) PRIMARY KEY,
        MaPhieuSuaChua INT NOT NULL,
        MaDichVu INT NULL,
        TrangThai NVARCHAR(50) NOT NULL,
        NoiDung NVARCHAR(1000) NOT NULL,
        NguoiCapNhat NVARCHAR(100) NOT NULL,
        ThoiGian DATETIME2(0) NOT NULL,
        CONSTRAINT FK_NhatKySuaChua_Phieu FOREIGN KEY (MaPhieuSuaChua)
            REFERENCES dbo.PhieuSuaChua(MaPhieuSuaChua)
    );
    CREATE INDEX IX_NhatKySuaChua_Phieu_ThoiGian
        ON dbo.NhatKySuaChua(MaPhieuSuaChua, ThoiGian, MaNhatKy);
END;
GO

IF COL_LENGTH(N'dbo.ThanhToan', N'MaYeuCau') IS NULL
    ALTER TABLE dbo.ThanhToan ADD MaYeuCau VARCHAR(36) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = N'UX_ThanhToan_MaYeuCau' AND object_id = OBJECT_ID(N'dbo.ThanhToan'))
    CREATE UNIQUE INDEX UX_ThanhToan_MaYeuCau ON dbo.ThanhToan(MaYeuCau)
        WHERE MaYeuCau IS NOT NULL;
GO
