-- Chay sau V006. Du lieu cu de NULL de doi chieu thu cong, khong tu dong xac minh.
USE QuanLyGaraOTo;
GO
IF COL_LENGTH('dbo.HopDongBaoHiem', 'TenChuXeTrenDangKy') IS NULL
    ALTER TABLE dbo.HopDongBaoHiem ADD TenChuXeTrenDangKy NVARCHAR(200) NULL;
GO
IF COL_LENGTH('dbo.HopDongBaoHiem', 'TenChuXeTrenChungNhan') IS NULL
    ALTER TABLE dbo.HopDongBaoHiem ADD TenChuXeTrenChungNhan NVARCHAR(200) NULL;
GO
