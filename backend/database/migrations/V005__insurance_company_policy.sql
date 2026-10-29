-- Chay sau cac migration V001-V004 va patch Repair_Safety_Procedures.sql.
-- Script thu cong, co the chay lai ma khong xoa du lieu.
USE QuanLyGaraOTo;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID(N'dbo.CongTyBaoHiem', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CongTyBaoHiem (
        MaCongTyBaoHiem INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        MaCongTy NVARCHAR(30) NOT NULL,
        TenCongTy NVARCHAR(200) NOT NULL,
        SoDienThoai NVARCHAR(30) NULL,
        Email NVARCHAR(150) NULL,
        DiaChi NVARCHAR(255) NULL,
        DauMoiGiamDinh NVARCHAR(150) NULL,
        LienHeGiamDinh NVARCHAR(150) NULL,
        DangHopTac BIT NOT NULL CONSTRAINT DF_CongTyBaoHiem_DangHopTac DEFAULT (1),
        CONSTRAINT UQ_CongTyBaoHiem_MaCongTy UNIQUE (MaCongTy)
    );
END
GO

IF OBJECT_ID(N'dbo.HopDongBaoHiem', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HopDongBaoHiem (
        MaHopDongBaoHiem INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        MaCongTyBaoHiem INT NOT NULL,
        MaXe INT NOT NULL,
        MaKhachHang INT NOT NULL,
        SoHopDong NVARCHAR(100) NOT NULL,
        LoaiBaoHiem NVARCHAR(30) NOT NULL,
        NgayBatDau DATE NOT NULL,
        NgayKetThuc DATE NOT NULL,
        SoTienBaoHiem DECIMAL(18,2) NULL,
        MucMienThuong DECIMAL(18,2) NULL,
        QuyenChonGara NVARCHAR(500) NULL,
        DieuKhoanPhuTung NVARCHAR(1000) NULL,
        ThamChieuChungNhan NVARCHAR(500) NULL,
        TrangThaiXacMinh NVARCHAR(20) NOT NULL CONSTRAINT DF_HopDongBaoHiem_XacMinh DEFAULT N'CHUA_XAC_MINH',
        GhiChuXacMinh NVARCHAR(1000) NULL,
        MaNhanVienXacMinh INT NULL,
        NgayXacMinh DATETIME2(0) NULL,
        NgayTao DATETIME2(0) NOT NULL CONSTRAINT DF_HopDongBaoHiem_NgayTao DEFAULT SYSDATETIME(),
        CONSTRAINT FK_HopDongBaoHiem_CongTy FOREIGN KEY (MaCongTyBaoHiem) REFERENCES dbo.CongTyBaoHiem(MaCongTyBaoHiem),
        CONSTRAINT FK_HopDongBaoHiem_Xe FOREIGN KEY (MaXe) REFERENCES dbo.Xe(MaXe),
        CONSTRAINT FK_HopDongBaoHiem_KhachHang FOREIGN KEY (MaKhachHang) REFERENCES dbo.KhachHang(MaKhachHang),
        CONSTRAINT FK_HopDongBaoHiem_NhanVien FOREIGN KEY (MaNhanVienXacMinh) REFERENCES dbo.NhanVien(MaNhanVien),
        CONSTRAINT UQ_HopDongBaoHiem_SoHopDong UNIQUE (MaCongTyBaoHiem, SoHopDong),
        CONSTRAINT CK_HopDongBaoHiem_Ngay CHECK (NgayKetThuc >= NgayBatDau),
        CONSTRAINT CK_HopDongBaoHiem_Tien CHECK ((SoTienBaoHiem IS NULL OR SoTienBaoHiem >= 0) AND (MucMienThuong IS NULL OR MucMienThuong >= 0)),
        CONSTRAINT CK_HopDongBaoHiem_TrangThai CHECK (TrangThaiXacMinh IN (N'CHUA_XAC_MINH', N'DA_XAC_MINH', N'KHONG_HOP_LE')),
        CONSTRAINT CK_HopDongBaoHiem_XacMinh CHECK ((TrangThaiXacMinh = N'CHUA_XAC_MINH' AND MaNhanVienXacMinh IS NULL AND NgayXacMinh IS NULL)
            OR (TrangThaiXacMinh <> N'CHUA_XAC_MINH' AND MaNhanVienXacMinh IS NOT NULL AND NgayXacMinh IS NOT NULL))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_HopDongBaoHiem_MaXe' AND object_id = OBJECT_ID(N'dbo.HopDongBaoHiem'))
    CREATE INDEX IX_HopDongBaoHiem_MaXe ON dbo.HopDongBaoHiem(MaXe, NgayKetThuc DESC);
GO
