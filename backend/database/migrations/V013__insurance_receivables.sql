SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF OBJECT_ID('dbo.DeNghiBoiThuong','U') IS NULL
    CREATE TABLE dbo.DeNghiBoiThuong (
        Id INT IDENTITY PRIMARY KEY, MaHoSoBaoHiem INT NOT NULL REFERENCES dbo.HoSoBaoHiem,
        MaBaoGia INT NOT NULL REFERENCES dbo.BaoGia, LanDieuChinh INT NOT NULL,
        NhanTienTaiGara BIT NOT NULL, MaChungTu INT NULL, SoQuyetDinh NVARCHAR(100) NULL,
        UNIQUE(MaHoSoBaoHiem,MaBaoGia,LanDieuChinh),
        FOREIGN KEY(MaHoSoBaoHiem,MaChungTu) REFERENCES dbo.ChungTuBaoHiem(MaHoSoBaoHiem,MaChungTu)
    );
IF OBJECT_ID('dbo.PhanBoDongBaoHiem','U') IS NULL
    CREATE TABLE dbo.PhanBoDongBaoHiem (
        DeNghiId INT NOT NULL REFERENCES dbo.DeNghiBoiThuong, DongBaoGia INT NOT NULL,
        Loai VARCHAR(10) NOT NULL CHECK(Loai IN('SERVICE','PART')), MaHang INT NOT NULL,
        Ten NVARCHAR(500) NOT NULL, ThanhTien DECIMAL(18,2) NOT NULL,
        DeNghi DECIMAL(18,2) NOT NULL,
        ChapThuan DECIMAL(18,2) NULL,
        PhaiThu DECIMAL(18,2) NULL,
        CHECK(DeNghi>=0 AND DeNghi<=ThanhTien),
        CHECK(ChapThuan>=0 AND ChapThuan<=DeNghi),
        CHECK(PhaiThu>=0 AND PhaiThu<=ChapThuan),
        PRIMARY KEY(DeNghiId,DongBaoGia), UNIQUE(DeNghiId,Loai,MaHang)
    );
IF OBJECT_ID('dbo.CongNoBaoHiem','U') IS NULL
    CREATE TABLE dbo.CongNoBaoHiem (
        MaHoaDon INT PRIMARY KEY REFERENCES dbo.HoaDon, DeNghiId INT NOT NULL UNIQUE REFERENCES dbo.DeNghiBoiThuong,
        BaoHiem DECIMAL(18,2) NOT NULL CHECK(BaoHiem>=0), KhachHang DECIMAL(18,2) NOT NULL CHECK(KhachHang>=0)
    );
IF OBJECT_ID('dbo.ThuBaoHiem','U') IS NULL
    CREATE TABLE dbo.ThuBaoHiem (
        MaThanhToan INT PRIMARY KEY REFERENCES dbo.ThanhToan, MaHoaDon INT NOT NULL REFERENCES dbo.CongNoBaoHiem,
        MaHoSoBaoHiem INT NOT NULL REFERENCES dbo.HoSoBaoHiem, MaChungTu INT NOT NULL,
        ThamChieu NVARCHAR(100) NOT NULL, UNIQUE(MaHoSoBaoHiem,ThamChieu),
        FOREIGN KEY(MaHoSoBaoHiem,MaChungTu) REFERENCES dbo.ChungTuBaoHiem(MaHoSoBaoHiem,MaChungTu)
    );
COMMIT;
