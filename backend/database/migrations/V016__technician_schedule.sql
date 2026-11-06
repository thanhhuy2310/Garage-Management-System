SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF COL_LENGTH('dbo.KyThuatVien','GioiHanXe') IS NULL
    ALTER TABLE dbo.KyThuatVien ADD GioiHanXe int NOT NULL CONSTRAINT DF_KTV_GioiHan DEFAULT 2 CONSTRAINT CK_KTV_GioiHan CHECK (GioiHanXe BETWEEN 1 AND 100);
IF OBJECT_ID('dbo.CaLamKyThuatVien','U') IS NULL
BEGIN
    CREATE TABLE dbo.CaLamKyThuatVien (
        Id int IDENTITY PRIMARY KEY, TenCa nvarchar(100) NOT NULL,
        BatDau time NOT NULL, KetThuc time NOT NULL,
        CONSTRAINT CK_CaLam_ThoiGian CHECK (BatDau < KetThuc)
    );
    INSERT INTO dbo.CaLamKyThuatVien(TenCa,BatDau,KetThuc) VALUES
        (N'Ca sáng','08:00','12:00'),(N'Ca chiều','13:00','17:00'),(N'Ca tối','17:00','19:00');
END;
IF OBJECT_ID('dbo.LichLamKyThuatVien','U') IS NULL
    CREATE TABLE dbo.LichLamKyThuatVien (
        MaKyThuatVien int NOT NULL REFERENCES dbo.KyThuatVien(MaNhanVien),
        Ngay date NOT NULL, MaCa int NOT NULL REFERENCES dbo.CaLamKyThuatVien(Id),
        CONSTRAINT PK_LichLamKyThuatVien PRIMARY KEY(MaKyThuatVien,Ngay,MaCa)
    );
COMMIT;
