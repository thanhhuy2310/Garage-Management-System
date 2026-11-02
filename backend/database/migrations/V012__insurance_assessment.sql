SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF COL_LENGTH('dbo.HoSoBaoHiem','PhienBanHoSo') IS NULL
    ALTER TABLE dbo.HoSoBaoHiem ADD PhienBanHoSo INT NOT NULL DEFAULT 0;
IF OBJECT_ID('dbo.ChungTuBaoHiem','U') IS NULL
    CREATE TABLE dbo.ChungTuBaoHiem (
        MaChungTu INT IDENTITY PRIMARY KEY,
        MaHoSoBaoHiem INT NOT NULL REFERENCES dbo.HoSoBaoHiem,
        Loai NVARCHAR(30) NOT NULL,
        TenTep NVARCHAR(180) NOT NULL,
        Kieu VARCHAR(50) NOT NULL,
        NoiDung VARBINARY(MAX) NOT NULL CHECK (DATALENGTH(NoiDung) BETWEEN 1 AND 2097152),
        MaNhanVien INT NOT NULL REFERENCES dbo.NhanVien,
        NgayTai DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        UNIQUE(MaHoSoBaoHiem,MaChungTu)
    );
IF OBJECT_ID('dbo.KetQuaGiamDinh','U') IS NULL
    CREATE TABLE dbo.KetQuaGiamDinh (
        Id INT IDENTITY PRIMARY KEY,
        MaHoSoBaoHiem INT NOT NULL REFERENCES dbo.HoSoBaoHiem,
        HangMuc UNIQUEIDENTIFIER NOT NULL,
        Lan INT NOT NULL CHECK (Lan>0),
        MoTa NVARCHAR(500) NOT NULL,
        KetQua NVARCHAR(1000) NOT NULL,
        MaChungTu INT NOT NULL,
        MaNhanVien INT NOT NULL REFERENCES dbo.NhanVien,
        NgayGhi DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        UNIQUE(MaHoSoBaoHiem,HangMuc,Lan),
        FOREIGN KEY (MaHoSoBaoHiem,MaChungTu) REFERENCES dbo.ChungTuBaoHiem(MaHoSoBaoHiem,MaChungTu)
    );
COMMIT;
