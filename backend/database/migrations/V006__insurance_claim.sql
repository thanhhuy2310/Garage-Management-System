-- Chay sau V005. Script thu cong, khong xoa/ghi de du lieu.
USE QuanLyGaraOTo;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID(N'dbo.HoSoBaoHiem', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HoSoBaoHiem (
        MaHoSoBaoHiem INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        MaHoSo NVARCHAR(40) NOT NULL,
        MaHoSoCongTy NVARCHAR(100) NULL,
        MaCongTyBaoHiem INT NOT NULL,
        MaHopDongBaoHiem INT NOT NULL,
        MaTiepNhan INT NOT NULL,
        MaXe INT NOT NULL,
        MaKhachHang INT NOT NULL,
        ThoiDiemSuCo DATETIME2(0) NOT NULL,
        DiaDiemSuCo NVARCHAR(255) NOT NULL,
        MoTaNguyenNhan NVARCHAR(1000) NOT NULL,
        MoTaTonThat NVARCHAR(2000) NOT NULL,
        NgayThongBao DATETIME2(0) NULL,
        GiamDinhVien NVARCHAR(150) NULL,
        LienHeGiamDinh NVARCHAR(150) NULL,
        TrangThai NVARCHAR(30) NOT NULL CONSTRAINT DF_HoSoBaoHiem_TrangThai DEFAULT N'MOI_TAO',
        MaNhanVienTao INT NOT NULL,
        NgayTao DATETIME2(0) NOT NULL CONSTRAINT DF_HoSoBaoHiem_NgayTao DEFAULT SYSDATETIME(),
        CONSTRAINT UQ_HoSoBaoHiem_MaHoSo UNIQUE (MaHoSo),
        CONSTRAINT UQ_HoSoBaoHiem_MaTiepNhan UNIQUE (MaTiepNhan),
        CONSTRAINT FK_HoSoBaoHiem_CongTy FOREIGN KEY (MaCongTyBaoHiem) REFERENCES dbo.CongTyBaoHiem(MaCongTyBaoHiem),
        CONSTRAINT FK_HoSoBaoHiem_HopDong FOREIGN KEY (MaHopDongBaoHiem) REFERENCES dbo.HopDongBaoHiem(MaHopDongBaoHiem),
        CONSTRAINT FK_HoSoBaoHiem_TiepNhan FOREIGN KEY (MaTiepNhan) REFERENCES dbo.PhieuTiepNhan(MaTiepNhan),
        CONSTRAINT FK_HoSoBaoHiem_Xe FOREIGN KEY (MaXe) REFERENCES dbo.Xe(MaXe),
        CONSTRAINT FK_HoSoBaoHiem_KhachHang FOREIGN KEY (MaKhachHang) REFERENCES dbo.KhachHang(MaKhachHang),
        CONSTRAINT FK_HoSoBaoHiem_NhanVien FOREIGN KEY (MaNhanVienTao) REFERENCES dbo.NhanVien(MaNhanVien),
        CONSTRAINT CK_HoSoBaoHiem_TrangThai CHECK (TrangThai IN (N'MOI_TAO', N'DA_THONG_BAO', N'CHO_GIAM_DINH', N'DANG_XU_LY', N'TU_CHOI', N'DA_DONG'))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_HoSoBaoHiem_SuCo' AND object_id = OBJECT_ID(N'dbo.HoSoBaoHiem'))
    CREATE UNIQUE INDEX UX_HoSoBaoHiem_SuCo ON dbo.HoSoBaoHiem(MaXe, ThoiDiemSuCo, DiaDiemSuCo);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_HoSoBaoHiem_MaHoSoCongTy' AND object_id = OBJECT_ID(N'dbo.HoSoBaoHiem'))
    CREATE UNIQUE INDEX UX_HoSoBaoHiem_MaHoSoCongTy ON dbo.HoSoBaoHiem(MaCongTyBaoHiem, MaHoSoCongTy) WHERE MaHoSoCongTy IS NOT NULL;
GO

IF OBJECT_ID(N'dbo.NhatKyHoSoBaoHiem', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.NhatKyHoSoBaoHiem (
        MaNhatKy BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        MaHoSoBaoHiem INT NOT NULL,
        MaNhanVien INT NOT NULL,
        HanhDong NVARCHAR(50) NOT NULL,
        TrangThaiTruoc NVARCHAR(30) NULL,
        TrangThaiSau NVARCHAR(30) NOT NULL,
        GhiChu NVARCHAR(1000) NULL,
        ThoiGian DATETIME2(0) NOT NULL CONSTRAINT DF_NhatKyHoSoBaoHiem_ThoiGian DEFAULT SYSDATETIME(),
        CONSTRAINT FK_NhatKyHoSoBaoHiem_HoSo FOREIGN KEY (MaHoSoBaoHiem) REFERENCES dbo.HoSoBaoHiem(MaHoSoBaoHiem),
        CONSTRAINT FK_NhatKyHoSoBaoHiem_NhanVien FOREIGN KEY (MaNhanVien) REFERENCES dbo.NhanVien(MaNhanVien)
    );
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_NhatKyHoSoBaoHiem_HoSo' AND object_id = OBJECT_ID(N'dbo.NhatKyHoSoBaoHiem'))
    CREATE INDEX IX_NhatKyHoSoBaoHiem_HoSo ON dbo.NhatKyHoSoBaoHiem(MaHoSoBaoHiem, MaNhatKy);
GO
