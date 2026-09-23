-- ============================================================
-- DATABASE: QuanLyGaraOTo
-- SQL Server
-- De tai: "Xay dung he thong quan ly gara sua chua o to"
-- Ban cap nhat:
--   1) Bo thuoc tinh ChuyenMon cua KyThuatVien.
--   2) Bo sung PhieuNhapKho / ChiTietPhieuNhap theo nghiep vu nhap kho BUC05.a.
--   3) Bo sung xac nhan su dung phu tung truoc khi tru ton kho.
--   4) Bo sung FUNCTION / PROCEDURE / TRIGGER phuc vu nghiep vu thuc te.
--   5) Bo sung du lieu mau lien ket xuyen suot cac nghiep vu.
-- ============================================================

IF DB_ID(N'QuanLyGaraOTo') IS NULL
BEGIN
    CREATE DATABASE QuanLyGaraOTo;
END
GO

USE QuanLyGaraOTo;
GO

SET NOCOUNT ON;
GO

-- ============================================================
-- 1. KHACH HANG - NHAN VIEN - KY THUAT VIEN - TAI KHOAN
-- ============================================================

CREATE TABLE KhachHang (
    MaKhachHang        INT IDENTITY(1,1) PRIMARY KEY,
    HoTen              NVARCHAR(100) NOT NULL,
    SoDienThoai        VARCHAR(20) NOT NULL,
    Email              VARCHAR(150) NULL,
    DiaChi             NVARCHAR(255) NULL
);
GO

CREATE UNIQUE INDEX UX_KhachHang_SoDienThoai
ON KhachHang(SoDienThoai);
GO

CREATE TABLE NhanVien (
    MaNhanVien         INT IDENTITY(1,1) PRIMARY KEY,
    HoTen              NVARCHAR(100) NOT NULL,
    SoDienThoai        VARCHAR(20) NULL,
    Email              VARCHAR(150) NULL,
    ChucVu             NVARCHAR(100) NOT NULL
);
GO

-- KyThuatVien la mot NhanVien. Theo yeu cau hien tai KHONG luu ChuyenMon.
CREATE TABLE KyThuatVien (
    MaNhanVien         INT PRIMARY KEY,

    CONSTRAINT FK_KyThuatVien_NhanVien
        FOREIGN KEY (MaNhanVien)
        REFERENCES NhanVien(MaNhanVien)
);
GO

CREATE TABLE TaiKhoan (
    MaTaiKhoan         INT IDENTITY(1,1) PRIMARY KEY,
    TenDangNhap        VARCHAR(100) NOT NULL,
    MatKhauHash        VARCHAR(255) NOT NULL,
    VaiTro             NVARCHAR(50) NOT NULL,
    TrangThai          BIT NOT NULL CONSTRAINT DF_TaiKhoan_TrangThai DEFAULT 1,

    MaKhachHang        INT NULL,
    MaNhanVien         INT NULL,

    CONSTRAINT UQ_TaiKhoan_TenDangNhap UNIQUE (TenDangNhap),

    CONSTRAINT FK_TaiKhoan_KhachHang
        FOREIGN KEY (MaKhachHang)
        REFERENCES KhachHang(MaKhachHang),

    CONSTRAINT FK_TaiKhoan_NhanVien
        FOREIGN KEY (MaNhanVien)
        REFERENCES NhanVien(MaNhanVien),

    CONSTRAINT CK_TaiKhoan_ChuSoHuu
        CHECK (
            (MaKhachHang IS NOT NULL AND MaNhanVien IS NULL)
            OR
            (MaKhachHang IS NULL AND MaNhanVien IS NOT NULL)
        )
);
GO

CREATE UNIQUE INDEX UX_TaiKhoan_MaKhachHang
ON TaiKhoan(MaKhachHang)
WHERE MaKhachHang IS NOT NULL;
GO

CREATE UNIQUE INDEX UX_TaiKhoan_MaNhanVien
ON TaiKhoan(MaNhanVien)
WHERE MaNhanVien IS NOT NULL;
GO

-- ============================================================
-- 2. DICH VU - KHO - PHU TUNG
-- ============================================================

CREATE TABLE DichVu (
    MaDichVu           INT IDENTITY(1,1) PRIMARY KEY,
    TenDichVu          NVARCHAR(150) NOT NULL,
    LoaiDichVu         NVARCHAR(100) NULL,
    DonGia             DECIMAL(18,2) NOT NULL,
    MoTa               NVARCHAR(500) NULL,

    CONSTRAINT CK_DichVu_DonGia CHECK (DonGia >= 0)
);
GO

CREATE TABLE Kho (
    MaKho              INT IDENTITY(1,1) PRIMARY KEY,
    TenKho             NVARCHAR(150) NOT NULL,
    DiaChi             NVARCHAR(255) NULL
);
GO

CREATE TABLE PhuTung (
    MaPhuTung          INT IDENTITY(1,1) PRIMARY KEY,
    MaKho              INT NOT NULL,
    TenPhuTung         NVARCHAR(150) NOT NULL,
    HangSanXuat        NVARCHAR(150) NULL,
    DonGia             DECIMAL(18,2) NOT NULL,
    SoLuongTon         INT NOT NULL CONSTRAINT DF_PhuTung_SoLuongTon DEFAULT 0,
    MucTonToiThieu     INT NOT NULL CONSTRAINT DF_PhuTung_MucTonToiThieu DEFAULT 0,

    CONSTRAINT FK_PhuTung_Kho
        FOREIGN KEY (MaKho)
        REFERENCES Kho(MaKho),

    CONSTRAINT CK_PhuTung_DonGia CHECK (DonGia >= 0),
    CONSTRAINT CK_PhuTung_SoLuongTon CHECK (SoLuongTon >= 0),
    CONSTRAINT CK_PhuTung_MucTonToiThieu CHECK (MucTonToiThieu >= 0)
);
GO

-- ============================================================
-- 3. XE - LICH HEN
-- ============================================================

CREATE TABLE Xe (
    MaXe               INT IDENTITY(1,1) PRIMARY KEY,
    MaKhachHang        INT NOT NULL,
    BienSo             VARCHAR(20) NOT NULL,
    HangXe             NVARCHAR(100) NULL,
    DongXe             NVARCHAR(100) NULL,
    NamSanXuat         SMALLINT NULL,
    SoKm               INT NULL,

    CONSTRAINT UQ_Xe_BienSo UNIQUE (BienSo),

    CONSTRAINT FK_Xe_KhachHang
        FOREIGN KEY (MaKhachHang)
        REFERENCES KhachHang(MaKhachHang),

    CONSTRAINT CK_Xe_SoKm CHECK (SoKm IS NULL OR SoKm >= 0)
);
GO

CREATE UNIQUE INDEX UX_Xe_MaXe_MaKhachHang
ON Xe(MaXe, MaKhachHang);
GO

CREATE TABLE LichHen (
    MaLichHen          INT IDENTITY(1,1) PRIMARY KEY,
    MaKhachHang        INT NOT NULL,
    MaXe               INT NOT NULL,
    MaDichVu           INT NULL,
    NgayHen            DATE NOT NULL,
    GioHen             TIME(0) NOT NULL,
    NoiDung            NVARCHAR(500) NULL,
    TrangThai          NVARCHAR(50) NOT NULL,

    CONSTRAINT FK_LichHen_KhachHang
        FOREIGN KEY (MaKhachHang)
        REFERENCES KhachHang(MaKhachHang),

    CONSTRAINT FK_LichHen_XeCuaKhach
        FOREIGN KEY (MaXe, MaKhachHang)
        REFERENCES Xe(MaXe, MaKhachHang),

    CONSTRAINT FK_LichHen_DichVu
        FOREIGN KEY (MaDichVu)
        REFERENCES DichVu(MaDichVu)
);
GO

-- ============================================================
-- 4. TIEP NHAN - SUA CHUA
-- ============================================================

CREATE TABLE PhieuTiepNhan (
    MaTiepNhan         INT IDENTITY(1,1) PRIMARY KEY,
    MaXe               INT NOT NULL,
    NgayTiepNhan       DATETIME2(0) NOT NULL,
    TinhTrangBanDau    NVARCHAR(1000) NULL,
    YeuCauKhachHang    NVARCHAR(1000) NULL,
    GhiChu             NVARCHAR(1000) NULL,

    CONSTRAINT FK_PhieuTiepNhan_Xe
        FOREIGN KEY (MaXe)
        REFERENCES Xe(MaXe)
);
GO

CREATE TABLE PhieuSuaChua (
    MaPhieuSuaChua     INT IDENTITY(1,1) PRIMARY KEY,
    MaTiepNhan         INT NOT NULL,
    NgayLap            DATETIME2(0) NOT NULL,
    NgayBatDau         DATETIME2(0) NULL,
    NgayHoanThanh      DATETIME2(0) NULL,
    TrangThai          NVARCHAR(50) NOT NULL,
    KetQua             NVARCHAR(1000) NULL,

    CONSTRAINT UQ_PhieuSuaChua_MaTiepNhan UNIQUE (MaTiepNhan),

    CONSTRAINT FK_PhieuSuaChua_PhieuTiepNhan
        FOREIGN KEY (MaTiepNhan)
        REFERENCES PhieuTiepNhan(MaTiepNhan),

    CONSTRAINT CK_PhieuSuaChua_Ngay
        CHECK (
            NgayHoanThanh IS NULL
            OR NgayBatDau IS NULL
            OR NgayHoanThanh >= NgayBatDau
        )
);
GO

-- De cuong co nghiep vu phan cong ky thuat vien.
-- Bang lien ket cho phep mot phieu sua chua co the co nhieu KTV.
CREATE TABLE PhanCongKyThuatVien (
    MaPhieuSuaChua     INT NOT NULL,
    MaKyThuatVien      INT NOT NULL,
    NgayPhanCong       DATETIME2(0) NOT NULL,
    GhiChu             NVARCHAR(500) NULL,

    CONSTRAINT PK_PhanCongKyThuatVien
        PRIMARY KEY (MaPhieuSuaChua, MaKyThuatVien),

    CONSTRAINT FK_PhanCong_PhieuSuaChua
        FOREIGN KEY (MaPhieuSuaChua)
        REFERENCES PhieuSuaChua(MaPhieuSuaChua),

    CONSTRAINT FK_PhanCong_KyThuatVien
        FOREIGN KEY (MaKyThuatVien)
        REFERENCES KyThuatVien(MaNhanVien)
);
GO

CREATE TABLE ChiTietDichVu (
    MaPhieuSuaChua     INT NOT NULL,
    MaDichVu           INT NOT NULL,
    SoLuong            INT NOT NULL CONSTRAINT DF_ChiTietDichVu_SoLuong DEFAULT 1,
    DonGia             DECIMAL(18,2) NOT NULL,
    TrangThai          NVARCHAR(50) NULL,
    ThanhTien AS (CONVERT(DECIMAL(18,2), SoLuong * DonGia)) PERSISTED,

    CONSTRAINT PK_ChiTietDichVu
        PRIMARY KEY (MaPhieuSuaChua, MaDichVu),

    CONSTRAINT FK_ChiTietDichVu_PhieuSuaChua
        FOREIGN KEY (MaPhieuSuaChua)
        REFERENCES PhieuSuaChua(MaPhieuSuaChua),

    CONSTRAINT FK_ChiTietDichVu_DichVu
        FOREIGN KEY (MaDichVu)
        REFERENCES DichVu(MaDichVu),

    CONSTRAINT CK_ChiTietDichVu_SoLuong CHECK (SoLuong > 0),
    CONSTRAINT CK_ChiTietDichVu_DonGia CHECK (DonGia >= 0)
);
GO

CREATE TABLE ChiTietPhuTung (
    MaPhieuSuaChua     INT NOT NULL,
    MaPhuTung          INT NOT NULL,
    SoLuong            INT NOT NULL,
    DonGia             DECIMAL(18,2) NOT NULL,
    ThanhTien AS (CONVERT(DECIMAL(18,2), SoLuong * DonGia)) PERSISTED,

    CONSTRAINT PK_ChiTietPhuTung
        PRIMARY KEY (MaPhieuSuaChua, MaPhuTung),

    CONSTRAINT FK_ChiTietPhuTung_PhieuSuaChua
        FOREIGN KEY (MaPhieuSuaChua)
        REFERENCES PhieuSuaChua(MaPhieuSuaChua),

    CONSTRAINT FK_ChiTietPhuTung_PhuTung
        FOREIGN KEY (MaPhuTung)
        REFERENCES PhuTung(MaPhuTung),

    CONSTRAINT CK_ChiTietPhuTung_SoLuong CHECK (SoLuong > 0),
    CONSTRAINT CK_ChiTietPhuTung_DonGia CHECK (DonGia >= 0)
);
GO

-- ============================================================
-- 5. BAO GIA
-- ============================================================

CREATE TABLE BaoGia (
    MaBaoGia           INT IDENTITY(1,1) PRIMARY KEY,
    MaPhieuSuaChua     INT NOT NULL,
    NgayLap            DATETIME2(0) NOT NULL,
    TongTien           DECIMAL(18,2) NOT NULL CONSTRAINT DF_BaoGia_TongTien DEFAULT 0,
    TrangThai          NVARCHAR(50) NOT NULL,
    NgayXacNhan        DATETIME2(0) NULL,

    CONSTRAINT UQ_BaoGia_MaPhieuSuaChua UNIQUE (MaPhieuSuaChua),

    CONSTRAINT FK_BaoGia_PhieuSuaChua
        FOREIGN KEY (MaPhieuSuaChua)
        REFERENCES PhieuSuaChua(MaPhieuSuaChua),

    CONSTRAINT CK_BaoGia_TongTien CHECK (TongTien >= 0)
);
GO

CREATE TABLE ChiTietBaoGia (
    MaChiTietBaoGia    INT IDENTITY(1,1) PRIMARY KEY,
    MaBaoGia           INT NOT NULL,
    MaDichVu           INT NULL,
    MaPhuTung          INT NULL,
    NoiDung            NVARCHAR(255) NOT NULL,
    SoLuong            INT NOT NULL,
    DonGia             DECIMAL(18,2) NOT NULL,
    ThanhTien AS (CONVERT(DECIMAL(18,2), SoLuong * DonGia)) PERSISTED,

    CONSTRAINT FK_ChiTietBaoGia_BaoGia
        FOREIGN KEY (MaBaoGia)
        REFERENCES BaoGia(MaBaoGia),

    CONSTRAINT FK_ChiTietBaoGia_DichVu
        FOREIGN KEY (MaDichVu)
        REFERENCES DichVu(MaDichVu),

    CONSTRAINT FK_ChiTietBaoGia_PhuTung
        FOREIGN KEY (MaPhuTung)
        REFERENCES PhuTung(MaPhuTung),

    CONSTRAINT CK_ChiTietBaoGia_LoaiHangMuc
        CHECK (
            (MaDichVu IS NOT NULL AND MaPhuTung IS NULL)
            OR
            (MaDichVu IS NULL AND MaPhuTung IS NOT NULL)
        ),

    CONSTRAINT CK_ChiTietBaoGia_SoLuong CHECK (SoLuong > 0),
    CONSTRAINT CK_ChiTietBaoGia_DonGia CHECK (DonGia >= 0)
);
GO

-- ============================================================
-- 6. NHAP KHO - XUAT KHO - BIEN DONG KHO
-- ============================================================

-- Bo sung theo BUC05.a Nhap kho va phieu nhap trong luong nghiep vu kho.
-- NhaCungCap hien luu dang text vi Nha cung cap la Business Actor,
-- chua co yeu cau quan ly danh muc nha cung cap nhu mot module he thong rieng.
CREATE TABLE PhieuNhapKho (
    MaPhieuNhap        INT IDENTITY(1,1) PRIMARY KEY,
    NgayNhap           DATETIME2(0) NOT NULL,
    NhaCungCap         NVARCHAR(200) NOT NULL,
    MaNhanVienKho      INT NOT NULL,
    GhiChu             NVARCHAR(500) NULL,

    CONSTRAINT FK_PhieuNhapKho_NhanVienKho
        FOREIGN KEY (MaNhanVienKho)
        REFERENCES NhanVien(MaNhanVien)
);
GO

CREATE TABLE ChiTietPhieuNhap (
    MaPhieuNhap        INT NOT NULL,
    MaPhuTung          INT NOT NULL,
    SoLuong            INT NOT NULL,
    DonGiaNhap         DECIMAL(18,2) NOT NULL,
    ThanhTien AS (CONVERT(DECIMAL(18,2), SoLuong * DonGiaNhap)) PERSISTED,

    CONSTRAINT PK_ChiTietPhieuNhap
        PRIMARY KEY (MaPhieuNhap, MaPhuTung),

    CONSTRAINT FK_ChiTietPhieuNhap_PhieuNhap
        FOREIGN KEY (MaPhieuNhap)
        REFERENCES PhieuNhapKho(MaPhieuNhap),

    CONSTRAINT FK_ChiTietPhieuNhap_PhuTung
        FOREIGN KEY (MaPhuTung)
        REFERENCES PhuTung(MaPhuTung),

    CONSTRAINT CK_ChiTietPhieuNhap_SoLuong CHECK (SoLuong > 0),
    CONSTRAINT CK_ChiTietPhieuNhap_DonGiaNhap CHECK (DonGiaNhap >= 0)
);
GO

CREATE TABLE PhieuXuatKho (
    MaPhieuXuat        INT IDENTITY(1,1) PRIMARY KEY,
    MaPhieuSuaChua     INT NULL,
    MaNhanVienKho      INT NOT NULL,
    MaKyThuatVienYeuCau INT NULL,
    NgayXuat           DATETIME2(0) NOT NULL,
    LyDo               NVARCHAR(500) NOT NULL,

    CONSTRAINT FK_PhieuXuatKho_PhieuSuaChua
        FOREIGN KEY (MaPhieuSuaChua)
        REFERENCES PhieuSuaChua(MaPhieuSuaChua),

    CONSTRAINT FK_PhieuXuatKho_NhanVienKho
        FOREIGN KEY (MaNhanVienKho)
        REFERENCES NhanVien(MaNhanVien),

    CONSTRAINT FK_PhieuXuatKho_KyThuatVienYeuCau
        FOREIGN KEY (MaKyThuatVienYeuCau)
        REFERENCES KyThuatVien(MaNhanVien)
);
GO

CREATE TABLE ChiTietPhieuXuat (
    MaPhieuXuat        INT NOT NULL,
    MaPhuTung          INT NOT NULL,
    SoLuong            INT NOT NULL,
    DonGia             DECIMAL(18,2) NULL,
    DaXacNhanSuDung    BIT NOT NULL CONSTRAINT DF_ChiTietPhieuXuat_DaXacNhan DEFAULT 0,
    NgayXacNhan        DATETIME2(0) NULL,
    MaKyThuatVienXacNhan INT NULL,

    CONSTRAINT PK_ChiTietPhieuXuat
        PRIMARY KEY (MaPhieuXuat, MaPhuTung),

    CONSTRAINT FK_ChiTietPhieuXuat_PhieuXuat
        FOREIGN KEY (MaPhieuXuat)
        REFERENCES PhieuXuatKho(MaPhieuXuat),

    CONSTRAINT FK_ChiTietPhieuXuat_PhuTung
        FOREIGN KEY (MaPhuTung)
        REFERENCES PhuTung(MaPhuTung),

    CONSTRAINT FK_ChiTietPhieuXuat_KyThuatVienXacNhan
        FOREIGN KEY (MaKyThuatVienXacNhan)
        REFERENCES KyThuatVien(MaNhanVien),

    CONSTRAINT CK_ChiTietPhieuXuat_SoLuong CHECK (SoLuong > 0),
    CONSTRAINT CK_ChiTietPhieuXuat_DonGia CHECK (DonGia IS NULL OR DonGia >= 0),
    CONSTRAINT CK_ChiTietPhieuXuat_XacNhan
        CHECK (
            (DaXacNhanSuDung = 0 AND NgayXacNhan IS NULL AND MaKyThuatVienXacNhan IS NULL)
            OR
            (DaXacNhanSuDung = 1 AND NgayXacNhan IS NOT NULL AND MaKyThuatVienXacNhan IS NOT NULL)
        )
);
GO

CREATE TABLE BienDongKho (
    MaBienDong         BIGINT IDENTITY(1,1) PRIMARY KEY,
    MaPhuTung          INT NOT NULL,
    MaPhieuNhap        INT NULL,
    MaPhieuXuat        INT NULL,
    ThoiGian           DATETIME2(0) NOT NULL,
    LoaiBienDong       NVARCHAR(20) NOT NULL,
    SoLuong            INT NOT NULL,
    SoLuongTruoc       INT NULL,
    SoLuongSau         INT NULL,
    GhiChu             NVARCHAR(500) NULL,

    CONSTRAINT FK_BienDongKho_PhuTung
        FOREIGN KEY (MaPhuTung)
        REFERENCES PhuTung(MaPhuTung),

    CONSTRAINT FK_BienDongKho_PhieuNhap
        FOREIGN KEY (MaPhieuNhap)
        REFERENCES PhieuNhapKho(MaPhieuNhap),

    CONSTRAINT FK_BienDongKho_PhieuXuat
        FOREIGN KEY (MaPhieuXuat)
        REFERENCES PhieuXuatKho(MaPhieuXuat),

    CONSTRAINT CK_BienDongKho_Loai
        CHECK (LoaiBienDong IN (N'NHAP', N'XUAT', N'KIEM_KE')),

    CONSTRAINT CK_BienDongKho_SoLuong
        CHECK (
            (LoaiBienDong IN (N'NHAP', N'XUAT') AND SoLuong > 0)
            OR
            (LoaiBienDong = N'KIEM_KE' AND SoLuong >= 0)
        ),

    CONSTRAINT CK_BienDongKho_ThamChieu
        CHECK (
            (LoaiBienDong = N'NHAP' AND MaPhieuNhap IS NOT NULL AND MaPhieuXuat IS NULL)
            OR
            (LoaiBienDong = N'XUAT' AND MaPhieuNhap IS NULL AND MaPhieuXuat IS NOT NULL)
            OR
            (LoaiBienDong = N'KIEM_KE' AND MaPhieuNhap IS NULL AND MaPhieuXuat IS NULL)
        ),

    CONSTRAINT CK_BienDongKho_SoLuongTruoc
        CHECK (SoLuongTruoc IS NULL OR SoLuongTruoc >= 0),

    CONSTRAINT CK_BienDongKho_SoLuongSau
        CHECK (SoLuongSau IS NULL OR SoLuongSau >= 0)
);
GO

-- ============================================================
-- 7. HOA DON - THANH TOAN
-- ============================================================

CREATE TABLE HoaDon (
    MaHoaDon           INT IDENTITY(1,1) PRIMARY KEY,
    MaPhieuSuaChua     INT NOT NULL,
    NgayLap            DATETIME2(0) NOT NULL,
    TongTien           DECIMAL(18,2) NOT NULL,
    TrangThai          NVARCHAR(50) NOT NULL,

    CONSTRAINT UQ_HoaDon_MaPhieuSuaChua UNIQUE (MaPhieuSuaChua),

    CONSTRAINT FK_HoaDon_PhieuSuaChua
        FOREIGN KEY (MaPhieuSuaChua)
        REFERENCES PhieuSuaChua(MaPhieuSuaChua),

    CONSTRAINT CK_HoaDon_TongTien CHECK (TongTien >= 0)
);
GO

CREATE TABLE ThanhToan (
    MaThanhToan        INT IDENTITY(1,1) PRIMARY KEY,
    MaHoaDon           INT NOT NULL,
    NgayThanhToan      DATETIME2(0) NOT NULL,
    SoTien             DECIMAL(18,2) NOT NULL,
    PhuongThuc         NVARCHAR(50) NOT NULL,

    CONSTRAINT FK_ThanhToan_HoaDon
        FOREIGN KEY (MaHoaDon)
        REFERENCES HoaDon(MaHoaDon),

    CONSTRAINT CK_ThanhToan_SoTien CHECK (SoTien > 0)
);
GO

-- ============================================================
-- 8. THONG BAO
-- ============================================================

CREATE TABLE ThongBao (
    MaThongBao         BIGINT IDENTITY(1,1) PRIMARY KEY,
    MaKhachHang        INT NOT NULL,
    MaLichHen          INT NULL,
    MaPhieuSuaChua     INT NULL,
    LoaiThongBao       NVARCHAR(50) NOT NULL,
    TieuDe             NVARCHAR(200) NOT NULL,
    NoiDung            NVARCHAR(1000) NOT NULL,
    ThoiGian           DATETIME2(0) NOT NULL,
    DaDoc              BIT NOT NULL CONSTRAINT DF_ThongBao_DaDoc DEFAULT 0,

    CONSTRAINT FK_ThongBao_KhachHang
        FOREIGN KEY (MaKhachHang)
        REFERENCES KhachHang(MaKhachHang),

    CONSTRAINT FK_ThongBao_LichHen
        FOREIGN KEY (MaLichHen)
        REFERENCES LichHen(MaLichHen),

    CONSTRAINT FK_ThongBao_PhieuSuaChua
        FOREIGN KEY (MaPhieuSuaChua)
        REFERENCES PhieuSuaChua(MaPhieuSuaChua)
);
GO

-- ============================================================
-- 9. INDEX THUONG DUNG
-- ============================================================

CREATE INDEX IX_Xe_MaKhachHang
ON Xe(MaKhachHang);
GO

CREATE INDEX IX_LichHen_MaKhachHang_NgayHen
ON LichHen(MaKhachHang, NgayHen);
GO

CREATE INDEX IX_PhieuTiepNhan_MaXe
ON PhieuTiepNhan(MaXe);
GO

CREATE INDEX IX_PhieuSuaChua_TrangThai
ON PhieuSuaChua(TrangThai);
GO

CREATE INDEX IX_PhieuNhapKho_NgayNhap
ON PhieuNhapKho(NgayNhap);
GO

CREATE INDEX IX_PhieuXuatKho_MaPhieuSuaChua
ON PhieuXuatKho(MaPhieuSuaChua);
GO

CREATE INDEX IX_BienDongKho_MaPhuTung_ThoiGian
ON BienDongKho(MaPhuTung, ThoiGian);
GO

CREATE INDEX IX_ThongBao_MaKhachHang_DaDoc
ON ThongBao(MaKhachHang, DaDoc);
GO

-- ============================================================
-- 10. FUNCTION
-- ============================================================

-- Tong chi phi thuc te cua mot phieu sua chua = dich vu + phu tung da dung.
CREATE OR ALTER FUNCTION dbo.fn_TinhTongChiPhiSuaChua (
    @MaPhieuSuaChua INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @TongDichVu DECIMAL(18,2) = 0;
    DECLARE @TongPhuTung DECIMAL(18,2) = 0;

    SELECT @TongDichVu = ISNULL(SUM(ThanhTien), 0)
    FROM ChiTietDichVu
    WHERE MaPhieuSuaChua = @MaPhieuSuaChua;

    SELECT @TongPhuTung = ISNULL(SUM(ThanhTien), 0)
    FROM ChiTietPhuTung
    WHERE MaPhieuSuaChua = @MaPhieuSuaChua;

    RETURN ISNULL(@TongDichVu, 0) + ISNULL(@TongPhuTung, 0);
END;
GO

-- Tong so tien da thanh toan cua mot hoa don.
CREATE OR ALTER FUNCTION dbo.fn_TongDaThanhToan (
    @MaHoaDon INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Tong DECIMAL(18,2);

    SELECT @Tong = ISNULL(SUM(SoTien), 0)
    FROM ThanhToan
    WHERE MaHoaDon = @MaHoaDon;

    RETURN ISNULL(@Tong, 0);
END;
GO

-- Trang thai ton kho duoc suy ra, khong can luu them cot trang thai.
CREATE OR ALTER FUNCTION dbo.fn_TrangThaiTonKho (
    @MaPhuTung INT
)
RETURNS NVARCHAR(20)
AS
BEGIN
    DECLARE @SoLuongTon INT;
    DECLARE @MucTonToiThieu INT;

    SELECT
        @SoLuongTon = SoLuongTon,
        @MucTonToiThieu = MucTonToiThieu
    FROM PhuTung
    WHERE MaPhuTung = @MaPhuTung;

    IF @SoLuongTon IS NULL
        RETURN N'KHONG_TON_TAI';

    IF @SoLuongTon = 0
        RETURN N'HET_HANG';

    IF @SoLuongTon <= @MucTonToiThieu
        RETURN N'SAP_HET';

    RETURN N'CON_HANG';
END;
GO

-- ============================================================
-- 11. PROCEDURE
-- ============================================================

-- Nhap mot phu tung vao phieu nhap va cap nhat ton kho + lich su bien dong.
CREATE OR ALTER PROCEDURE dbo.sp_ThemChiTietPhieuNhap
    @MaPhieuNhap INT,
    @MaPhuTung INT,
    @SoLuong INT,
    @DonGiaNhap DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @SoLuong <= 0
        THROW 50001, N'So luong nhap phai lon hon 0.', 1;

    IF @DonGiaNhap < 0
        THROW 50002, N'Don gia nhap khong hop le.', 1;

    IF NOT EXISTS (SELECT 1 FROM PhieuNhapKho WHERE MaPhieuNhap = @MaPhieuNhap)
        THROW 50003, N'Phieu nhap kho khong ton tai.', 1;

    IF NOT EXISTS (SELECT 1 FROM PhuTung WHERE MaPhuTung = @MaPhuTung)
        THROW 50004, N'Phu tung khong ton tai.', 1;

    IF EXISTS (
        SELECT 1
        FROM ChiTietPhieuNhap
        WHERE MaPhieuNhap = @MaPhieuNhap
          AND MaPhuTung = @MaPhuTung
    )
        THROW 50005, N'Phu tung da co trong phieu nhap nay.', 1;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @TonTruoc INT;
        DECLARE @TonSau INT;

        SELECT @TonTruoc = SoLuongTon
        FROM PhuTung WITH (UPDLOCK, HOLDLOCK)
        WHERE MaPhuTung = @MaPhuTung;

        INSERT INTO ChiTietPhieuNhap (MaPhieuNhap, MaPhuTung, SoLuong, DonGiaNhap)
        VALUES (@MaPhieuNhap, @MaPhuTung, @SoLuong, @DonGiaNhap);

        SET @TonSau = @TonTruoc + @SoLuong;

        UPDATE PhuTung
        SET SoLuongTon = @TonSau
        WHERE MaPhuTung = @MaPhuTung;

        INSERT INTO BienDongKho (
            MaPhuTung, MaPhieuNhap, MaPhieuXuat,
            ThoiGian, LoaiBienDong, SoLuong,
            SoLuongTruoc, SoLuongSau, GhiChu
        )
        VALUES (
            @MaPhuTung, @MaPhieuNhap, NULL,
            SYSDATETIME(), N'NHAP', @SoLuong,
            @TonTruoc, @TonSau, N'Nhap kho theo phieu nhap'
        );

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- KTV xac nhan phu tung da su dung/thay the.
-- Chi luc nay moi tru ton kho, dung voi luong nghiep vu da chot.
CREATE OR ALTER PROCEDURE dbo.sp_XacNhanSuDungPhuTung
    @MaPhieuXuat INT,
    @MaPhuTung INT,
    @MaKyThuatVien INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @MaPhieuSuaChua INT;
    DECLARE @SoLuong INT;
    DECLARE @DonGia DECIMAL(18,2);
    DECLARE @DaXacNhan BIT;

    SELECT
        @MaPhieuSuaChua = px.MaPhieuSuaChua,
        @SoLuong = ct.SoLuong,
        @DonGia = COALESCE(ct.DonGia, pt.DonGia),
        @DaXacNhan = ct.DaXacNhanSuDung
    FROM ChiTietPhieuXuat ct
    INNER JOIN PhieuXuatKho px ON px.MaPhieuXuat = ct.MaPhieuXuat
    INNER JOIN PhuTung pt ON pt.MaPhuTung = ct.MaPhuTung
    WHERE ct.MaPhieuXuat = @MaPhieuXuat
      AND ct.MaPhuTung = @MaPhuTung;

    IF @SoLuong IS NULL
        THROW 50010, N'Khong tim thay chi tiet phieu xuat.', 1;

    IF @MaPhieuSuaChua IS NULL
        THROW 50011, N'Phieu xuat nay khong gan voi phieu sua chua.', 1;

    IF @DaXacNhan = 1
        THROW 50012, N'Phu tung nay da duoc xac nhan su dung.', 1;

    IF NOT EXISTS (
        SELECT 1
        FROM PhanCongKyThuatVien
        WHERE MaPhieuSuaChua = @MaPhieuSuaChua
          AND MaKyThuatVien = @MaKyThuatVien
    )
        THROW 50013, N'Ky thuat vien khong duoc phan cong cho phieu sua chua nay.', 1;

    IF NOT EXISTS (
        SELECT 1
        FROM BaoGia
        WHERE MaPhieuSuaChua = @MaPhieuSuaChua
          AND TrangThai = N'DA_XAC_NHAN'
    )
        THROW 50014, N'Bao gia chua duoc khach hang xac nhan.', 1;

    IF NOT EXISTS (
        SELECT 1
        FROM PhieuSuaChua
        WHERE MaPhieuSuaChua = @MaPhieuSuaChua
          AND TrangThai IN (N'DANG_SUA', N'CHO_PHU_TUNG')
    )
        THROW 50016, N'Phieu sua chua khong o trang thai cho phep xac nhan su dung phu tung.', 1;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @TonTruoc INT;
        DECLARE @TonSau INT;

        SELECT @TonTruoc = SoLuongTon
        FROM PhuTung WITH (UPDLOCK, HOLDLOCK)
        WHERE MaPhuTung = @MaPhuTung;

        IF @TonTruoc < @SoLuong
            THROW 50015, N'So luong ton kho khong du de xac nhan su dung.', 1;

        SET @TonSau = @TonTruoc - @SoLuong;

        UPDATE PhuTung
        SET SoLuongTon = @TonSau
        WHERE MaPhuTung = @MaPhuTung;

        UPDATE ChiTietPhieuXuat
        SET
            DaXacNhanSuDung = 1,
            NgayXacNhan = SYSDATETIME(),
            MaKyThuatVienXacNhan = @MaKyThuatVien
        WHERE MaPhieuXuat = @MaPhieuXuat
          AND MaPhuTung = @MaPhuTung;

        IF EXISTS (
            SELECT 1
            FROM ChiTietPhuTung
            WHERE MaPhieuSuaChua = @MaPhieuSuaChua
              AND MaPhuTung = @MaPhuTung
        )
        BEGIN
            UPDATE ChiTietPhuTung
            SET
                SoLuong = SoLuong + @SoLuong,
                DonGia = @DonGia
            WHERE MaPhieuSuaChua = @MaPhieuSuaChua
              AND MaPhuTung = @MaPhuTung;
        END
        ELSE
        BEGIN
            INSERT INTO ChiTietPhuTung (
                MaPhieuSuaChua, MaPhuTung, SoLuong, DonGia
            )
            VALUES (
                @MaPhieuSuaChua, @MaPhuTung, @SoLuong, @DonGia
            );
        END

        INSERT INTO BienDongKho (
            MaPhuTung, MaPhieuNhap, MaPhieuXuat,
            ThoiGian, LoaiBienDong, SoLuong,
            SoLuongTruoc, SoLuongSau, GhiChu
        )
        VALUES (
            @MaPhuTung, NULL, @MaPhieuXuat,
            SYSDATETIME(), N'XUAT', @SoLuong,
            @TonTruoc, @TonSau,
            N'KTV xac nhan da su dung/thay phu tung cho phieu sua chua'
        );

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- Kiem ke: cap nhat ton thuc te va ghi lich su bien dong.
CREATE OR ALTER PROCEDURE dbo.sp_KiemKeTonKho
    @MaPhuTung INT,
    @SoLuongThucTe INT,
    @GhiChu NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @SoLuongThucTe < 0
        THROW 50020, N'So luong thuc te khong duoc am.', 1;

    IF NOT EXISTS (SELECT 1 FROM PhuTung WHERE MaPhuTung = @MaPhuTung)
        THROW 50021, N'Phu tung khong ton tai.', 1;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @TonTruoc INT;
        DECLARE @ChenhLech INT;

        SELECT @TonTruoc = SoLuongTon
        FROM PhuTung WITH (UPDLOCK, HOLDLOCK)
        WHERE MaPhuTung = @MaPhuTung;

        SET @ChenhLech = ABS(@SoLuongThucTe - @TonTruoc);

        UPDATE PhuTung
        SET SoLuongTon = @SoLuongThucTe
        WHERE MaPhuTung = @MaPhuTung;

        INSERT INTO BienDongKho (
            MaPhuTung, MaPhieuNhap, MaPhieuXuat,
            ThoiGian, LoaiBienDong, SoLuong,
            SoLuongTruoc, SoLuongSau, GhiChu
        )
        VALUES (
            @MaPhuTung, NULL, NULL,
            SYSDATETIME(), N'KIEM_KE', @ChenhLech,
            @TonTruoc, @SoLuongThucTe,
            COALESCE(@GhiChu, N'Kiem ke ton kho')
        );

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- Khach hang xac nhan / khong dong y bao gia.
CREATE OR ALTER PROCEDURE dbo.sp_XacNhanBaoGia
    @MaBaoGia INT,
    @DongY BIT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM BaoGia WHERE MaBaoGia = @MaBaoGia)
        THROW 50030, N'Bao gia khong ton tai.', 1;

    UPDATE BaoGia
    SET
        TrangThai = CASE WHEN @DongY = 1 THEN N'DA_XAC_NHAN' ELSE N'KHONG_DONG_Y' END,
        NgayXacNhan = SYSDATETIME()
    WHERE MaBaoGia = @MaBaoGia;
END;
GO

-- Ghi nhan thanh toan, khong cho thanh toan vuot tong hoa don.
CREATE OR ALTER PROCEDURE dbo.sp_GhiNhanThanhToan
    @MaHoaDon INT,
    @SoTien DECIMAL(18,2),
    @PhuongThuc NVARCHAR(50),
    @NgayThanhToan DATETIME2(0) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @SoTien <= 0
        THROW 50040, N'So tien thanh toan phai lon hon 0.', 1;

    DECLARE @TongHoaDon DECIMAL(18,2);
    DECLARE @DaThanhToan DECIMAL(18,2);

    SELECT @TongHoaDon = TongTien
    FROM HoaDon
    WHERE MaHoaDon = @MaHoaDon;

    IF @TongHoaDon IS NULL
        THROW 50041, N'Hoa don khong ton tai.', 1;

    SET @DaThanhToan = dbo.fn_TongDaThanhToan(@MaHoaDon);

    IF @DaThanhToan + @SoTien > @TongHoaDon
        THROW 50042, N'So tien thanh toan vuot qua so tien con lai cua hoa don.', 1;

    BEGIN TRY
        BEGIN TRAN;

        INSERT INTO ThanhToan (MaHoaDon, NgayThanhToan, SoTien, PhuongThuc)
        VALUES (
            @MaHoaDon,
            COALESCE(@NgayThanhToan, SYSDATETIME()),
            @SoTien,
            @PhuongThuc
        );

        SET @DaThanhToan = @DaThanhToan + @SoTien;

        UPDATE HoaDon
        SET TrangThai = CASE
            WHEN @DaThanhToan >= TongTien THEN N'DA_THANH_TOAN'
            ELSE N'CHUA_THANH_TOAN'
        END
        WHERE MaHoaDon = @MaHoaDon;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- ============================================================
-- 12. TRIGGER
-- ============================================================

-- Tu dong tinh lai TongTien cua BaoGia theo ChiTietBaoGia.
CREATE OR ALTER TRIGGER dbo.TRG_ChiTietBaoGia_CapNhatTongTien
ON dbo.ChiTietBaoGia
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH BaoGiaBiAnhHuong AS (
        SELECT MaBaoGia FROM inserted
        UNION
        SELECT MaBaoGia FROM deleted
    )
    UPDATE bg
    SET TongTien = ISNULL(x.TongTien, 0)
    FROM BaoGia bg
    INNER JOIN BaoGiaBiAnhHuong a ON a.MaBaoGia = bg.MaBaoGia
    OUTER APPLY (
        SELECT SUM(ct.ThanhTien) AS TongTien
        FROM ChiTietBaoGia ct
        WHERE ct.MaBaoGia = bg.MaBaoGia
    ) x;
END;
GO

-- Khi phieu sua chua chuyen sang HOAN_TAT, tao thong bao cho khach hang.
CREATE OR ALTER TRIGGER dbo.TRG_PhieuSuaChua_ThongBaoHoanTat
ON dbo.PhieuSuaChua
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO ThongBao (
        MaKhachHang,
        MaLichHen,
        MaPhieuSuaChua,
        LoaiThongBao,
        TieuDe,
        NoiDung,
        ThoiGian,
        DaDoc
    )
    SELECT
        x.MaKhachHang,
        NULL,
        i.MaPhieuSuaChua,
        N'HOAN_TAT_SUA_CHUA',
        N'Xe da hoan tat sua chua',
        N'Phieu sua chua #' + CONVERT(NVARCHAR(20), i.MaPhieuSuaChua)
            + N' da hoan tat. Vui long lien he gara de nhan xe.',
        SYSDATETIME(),
        0
    FROM inserted i
    LEFT JOIN deleted d
        ON d.MaPhieuSuaChua = i.MaPhieuSuaChua
    INNER JOIN PhieuTiepNhan ptn
        ON ptn.MaTiepNhan = i.MaTiepNhan
    INNER JOIN Xe x
        ON x.MaXe = ptn.MaXe
    WHERE i.TrangThai = N'HOAN_TAT'
      AND (d.MaPhieuSuaChua IS NULL OR ISNULL(d.TrangThai, N'') <> N'HOAN_TAT')
      AND NOT EXISTS (
          SELECT 1
          FROM ThongBao tb
          WHERE tb.MaPhieuSuaChua = i.MaPhieuSuaChua
            AND tb.LoaiThongBao = N'HOAN_TAT_SUA_CHUA'
      );
END;
GO

-- ============================================================
-- 13. DU LIEU MAU
-- Du lieu gia lap phuc vu demo giao dien / nghiep vu.
-- Tai khoan mau dung chung mat khau demo123 (BCrypt), chi phuc vu moi truong demo.
-- ============================================================

INSERT INTO KhachHang (HoTen, SoDienThoai, Email, DiaChi)
VALUES
(N'Nguyen Van An', '0900000001', 'an.nguyen@example.com', N'Quan 7, TP.HCM'),
(N'Tran Minh Tuan', '0900000002', 'tuan.tran@example.com', N'Quan 10, TP.HCM'),
(N'Le Hoang Nam', '0900000003', 'nam.le@example.com', N'Thu Duc, TP.HCM'),
(N'Pham Ngoc Lan', '0900000004', 'lan.pham@example.com', N'Binh Thanh, TP.HCM');
GO

INSERT INTO NhanVien (HoTen, SoDienThoai, Email, ChucVu)
VALUES
(N'Nguyen Minh Anh', '0911000001', 'minhanh@garage.local', N'NHAN_VIEN_TIEP_NHAN'),
(N'Tran Quoc Bao',   '0911000002', 'quocbao@garage.local', N'KY_THUAT_VIEN'),
(N'Le Van Hung',      '0911000003', 'vanhung@garage.local', N'KY_THUAT_VIEN'),
(N'Pham Thu Ha',      '0911000004', 'thuha@garage.local', N'NHAN_VIEN_KHO'),
(N'Vo Thanh Nam',     '0911000005', 'thanhnam@garage.local', N'QUAN_LY'),
(N'Nguyen Hoang Long','0911000006', 'hoanglong@garage.local', N'QUAN_TRI_VIEN');
GO

INSERT INTO KyThuatVien (MaNhanVien)
VALUES (2), (3);
GO

INSERT INTO TaiKhoan (TenDangNhap, MatKhauHash, VaiTro, TrangThai, MaKhachHang, MaNhanVien)
VALUES
('khach01',   '$2a$10$cmQuil5sXrlLUZ540DVtcuEAIKD4PNfBsj9F0Z2iCby2wUQmaWppK', N'CUSTOMER',     1, 1, NULL),
('tiepnhan',  '$2a$10$cmQuil5sXrlLUZ540DVtcuEAIKD4PNfBsj9F0Z2iCby2wUQmaWppK', N'RECEPTIONIST', 1, NULL, 1),
('ktvbao',    '$2a$10$cmQuil5sXrlLUZ540DVtcuEAIKD4PNfBsj9F0Z2iCby2wUQmaWppK', N'TECHNICIAN',   1, NULL, 2),
('ktvhung',   '$2a$10$cmQuil5sXrlLUZ540DVtcuEAIKD4PNfBsj9F0Z2iCby2wUQmaWppK', N'TECHNICIAN',   1, NULL, 3),
('kho',       '$2a$10$cmQuil5sXrlLUZ540DVtcuEAIKD4PNfBsj9F0Z2iCby2wUQmaWppK', N'WAREHOUSE',    1, NULL, 4),
('manager',   '$2a$10$cmQuil5sXrlLUZ540DVtcuEAIKD4PNfBsj9F0Z2iCby2wUQmaWppK', N'MANAGER',      1, NULL, 5),
('admin',     '$2a$10$cmQuil5sXrlLUZ540DVtcuEAIKD4PNfBsj9F0Z2iCby2wUQmaWppK', N'ADMIN',        1, NULL, 6);
GO

INSERT INTO DichVu (TenDichVu, LoaiDichVu, DonGia, MoTa)
VALUES
(N'Thay dau dong co', N'BAO_DUONG', 450000, N'Thay dau dong co theo dung cap dau khuyen nghi.'),
(N'Bao duong dinh ky', N'BAO_DUONG', 1200000, N'Kiem tra tong quat cac hang muc bao duong dinh ky.'),
(N'Kiem tra he thong phanh', N'KIEM_TRA', 300000, N'Kiem tra dia phanh, ma phanh, dau phanh va he thong lien quan.'),
(N'Thay ma phanh truoc', N'SUA_CHUA', 500000, N'Cong thay ma phanh truoc.'),
(N'Ve sinh kim phun', N'BAO_DUONG', 700000, N'Ve sinh kim phun nhien lieu.'),
(N'Kiem tra dieu hoa', N'KIEM_TRA', 250000, N'Kiem tra kha nang lam lanh va cac thanh phan co ban cua he thong dieu hoa.');
GO

INSERT INTO Kho (TenKho, DiaChi)
VALUES (N'Kho phu tung chinh', N'Khu vuc kho - Gara trung tam');
GO

-- SoLuongTon ban dau = 0. Ton kho se duoc tang bang phieu nhap / procedure.
INSERT INTO PhuTung (MaKho, TenPhuTung, HangSanXuat, DonGia, SoLuongTon, MucTonToiThieu)
VALUES
(1, N'Loc dau dong co', N'Toyota Genuine Parts', 180000, 0, 5),
(1, N'Dau dong co 5W-30 4L', N'Castrol', 520000, 0, 6),
(1, N'Ma phanh truoc', N'Bosch', 950000, 0, 4),
(1, N'Loc gio dong co', N'Denso', 320000, 0, 4),
(1, N'Bugi', N'NGK', 180000, 0, 8),
(1, N'Nuoc lam mat 4L', N'Toyota', 250000, 0, 4),
(1, N'Loc dieu hoa', N'Denso', 280000, 0, 5);
GO

INSERT INTO Xe (MaKhachHang, BienSo, HangXe, DongXe, NamSanXuat, SoKm)
VALUES
(1, '51A-123.45', N'Toyota', N'Vios', 2021, 48250),
(2, '59K-456.78', N'Honda', N'City', 2020, 62100),
(3, '50H-234.56', N'Mazda', N'Mazda 3', 2022, 31800),
(4, '51K-789.01', N'Kia', N'Seltos', 2023, 18400);
GO

INSERT INTO LichHen (MaKhachHang, MaXe, MaDichVu, NgayHen, GioHen, NoiDung, TrangThai)
VALUES
(1, 1, 2, '2026-09-18', '09:00', N'Bao duong dinh ky, kiem tra dau may va loc dau.', N'DA_XAC_NHAN'),
(2, 2, 3, '2026-09-18', '14:00', N'Phanh co tieng keu khi dap.', N'HOAN_TAT'),
(3, 3, 6, '2026-09-19', '10:00', N'Dieu hoa lam lanh cham.', N'CHO_XAC_NHAN'),
(4, 4, 1, '2026-09-20', '08:30', N'Thay dau dong co dinh ky.', N'DA_XAC_NHAN');
GO

INSERT INTO PhieuTiepNhan (MaXe, NgayTiepNhan, TinhTrangBanDau, YeuCauKhachHang, GhiChu)
VALUES
(2, '2026-09-18T13:50:00', N'Xe van hanh duoc, co tieng rit nhe khi dap phanh.', N'Kiem tra he thong phanh va xu ly tieng keu.', N'Tiep nhan theo lich hen trong ngay.'),
(1, '2026-09-18T08:50:00', N'Xe hoat dong binh thuong, den bao bao duong dang sang.', N'Bao duong dinh ky, thay dau va kiem tra cac loc.', N'Khach de xe tai gara.'),
(4, '2026-08-20T09:10:00', N'Dieu hoa lam lanh kem sau khi khoi dong.', N'Kiem tra dieu hoa.', N'Lich su sua chua mau thang truoc.');
GO

INSERT INTO PhieuSuaChua (MaTiepNhan, NgayLap, NgayBatDau, NgayHoanThanh, TrangThai, KetQua)
VALUES
(1, '2026-09-18T14:10:00', '2026-09-18T14:20:00', NULL, N'DANG_SUA', NULL),
(2, '2026-09-18T09:10:00', '2026-09-18T09:30:00', NULL, N'DANG_SUA', NULL),
(3, '2026-08-20T09:30:00', '2026-08-20T09:45:00', '2026-08-20T11:00:00', N'HOAN_TAT', N'Da kiem tra dieu hoa, ve sinh co ban va he thong hoat dong binh thuong.');
GO

INSERT INTO PhanCongKyThuatVien (MaPhieuSuaChua, MaKyThuatVien, NgayPhanCong, GhiChu)
VALUES
(1, 2, '2026-09-18T14:15:00', N'Kiem tra va xu ly he thong phanh.'),
(2, 3, '2026-09-18T09:15:00', N'Thuc hien bao duong dinh ky.'),
(3, 2, '2026-08-20T09:35:00', N'Kiem tra he thong dieu hoa.');
GO

INSERT INTO ChiTietDichVu (MaPhieuSuaChua, MaDichVu, SoLuong, DonGia, TrangThai)
VALUES
(1, 3, 1, 300000, N'HOAN_TAT'),
(1, 4, 1, 500000, N'HOAN_TAT'),
(2, 2, 1, 1200000, N'DANG_THUC_HIEN'),
(3, 6, 1, 250000, N'HOAN_TAT');
GO

-- ----------------------------
-- Nhap kho mau
-- ----------------------------
INSERT INTO PhieuNhapKho (NgayNhap, NhaCungCap, MaNhanVienKho, GhiChu)
VALUES
('2026-09-01T08:30:00', N'Cong ty Phu Tung Minh Phat', 4, N'Nhap kho dau thang 09/2026'),
('2026-09-15T09:00:00', N'Nha phan phoi Phu Tung Thanh Cong', 4, N'Bo sung cac mat hang co muc ton thap');
GO

EXEC dbo.sp_ThemChiTietPhieuNhap 1, 1, 20, 120000;
EXEC dbo.sp_ThemChiTietPhieuNhap 1, 2, 18, 390000;
EXEC dbo.sp_ThemChiTietPhieuNhap 1, 3, 10, 720000;
EXEC dbo.sp_ThemChiTietPhieuNhap 1, 4, 12, 230000;
EXEC dbo.sp_ThemChiTietPhieuNhap 1, 5, 30, 120000;
EXEC dbo.sp_ThemChiTietPhieuNhap 1, 6, 12, 175000;
EXEC dbo.sp_ThemChiTietPhieuNhap 1, 7, 15, 195000;
EXEC dbo.sp_ThemChiTietPhieuNhap 2, 1, 10, 125000;
EXEC dbo.sp_ThemChiTietPhieuNhap 2, 2, 8, 395000;
EXEC dbo.sp_ThemChiTietPhieuNhap 2, 3, 6, 730000;
GO

-- ----------------------------
-- Bao gia mau
-- TongTien duoc trigger tu dong tinh lai khi them chi tiet.
-- ----------------------------
INSERT INTO BaoGia (MaPhieuSuaChua, NgayLap, TongTien, TrangThai, NgayXacNhan)
VALUES
(1, '2026-09-18T14:25:00', 0, N'CHO_XAC_NHAN', NULL),
(2, '2026-09-18T09:20:00', 0, N'CHO_XAC_NHAN', NULL),
(3, '2026-08-20T09:40:00', 0, N'CHO_XAC_NHAN', NULL);
GO

INSERT INTO ChiTietBaoGia (MaBaoGia, MaDichVu, MaPhuTung, NoiDung, SoLuong, DonGia)
VALUES
(1, 3, NULL, N'Kiem tra he thong phanh', 1, 300000),
(1, 4, NULL, N'Cong thay ma phanh truoc', 1, 500000),
(1, NULL, 3, N'Ma phanh truoc Bosch', 1, 950000),

(2, 2, NULL, N'Bao duong dinh ky', 1, 1200000),
(2, NULL, 1, N'Loc dau dong co', 1, 180000),
(2, NULL, 2, N'Dau dong co 5W-30 4L', 1, 520000),

(3, 6, NULL, N'Kiem tra dieu hoa', 1, 250000);
GO

EXEC dbo.sp_XacNhanBaoGia 1, 1;
EXEC dbo.sp_XacNhanBaoGia 2, 1;
EXEC dbo.sp_XacNhanBaoGia 3, 1;
GO

-- ----------------------------
-- Xuat kho mau
-- Phu tung chi bi tru ton khi KTV xac nhan da su dung.
-- ----------------------------
INSERT INTO PhieuXuatKho (MaPhieuSuaChua, MaNhanVienKho, MaKyThuatVienYeuCau, NgayXuat, LyDo)
VALUES
(1, 4, 2, '2026-09-18T14:40:00', N'Cap ma phanh cho phieu sua chua #1'),
(2, 4, 3, '2026-09-18T09:45:00', N'Cap phu tung bao duong cho phieu sua chua #2');
GO

INSERT INTO ChiTietPhieuXuat (MaPhieuXuat, MaPhuTung, SoLuong, DonGia)
VALUES
(1, 3, 1, 950000),
(2, 1, 1, 180000),
(2, 2, 1, 520000);
GO

EXEC dbo.sp_XacNhanSuDungPhuTung 1, 3, 2;
EXEC dbo.sp_XacNhanSuDungPhuTung 2, 1, 3;
EXEC dbo.sp_XacNhanSuDungPhuTung 2, 2, 3;
GO

-- Hoan tat phieu #1 sau khi KTV da xac nhan phu tung su dung.
UPDATE PhieuSuaChua
SET
    NgayHoanThanh = '2026-09-18T16:20:00',
    TrangThai = N'HOAN_TAT',
    KetQua = N'Da thay ma phanh truoc va kiem tra lai he thong phanh, van hanh on dinh.'
WHERE MaPhieuSuaChua = 1;
GO

-- ----------------------------
-- Hoa don / thanh toan mau
-- Chi tao hoa don cho cac phieu da hoan tat.
-- ----------------------------
INSERT INTO HoaDon (MaPhieuSuaChua, NgayLap, TongTien, TrangThai)
VALUES
(1, '2026-09-18T16:25:00', dbo.fn_TinhTongChiPhiSuaChua(1), N'CHUA_THANH_TOAN'),
(3, '2026-08-20T11:05:00', dbo.fn_TinhTongChiPhiSuaChua(3), N'CHUA_THANH_TOAN');
GO

EXEC dbo.sp_GhiNhanThanhToan 1, 1750000, N'CHUYEN_KHOAN', '2026-09-18T16:35:00';
EXEC dbo.sp_GhiNhanThanhToan 2, 250000, N'TIEN_MAT', '2026-08-20T11:10:00';
GO

-- ----------------------------
-- Thong bao mau bo sung
-- Trigger da tu tao thong bao HOAN_TAT_SUA_CHUA cho cac phieu hoan tat.
-- ----------------------------
INSERT INTO ThongBao (
    MaKhachHang, MaLichHen, MaPhieuSuaChua,
    LoaiThongBao, TieuDe, NoiDung, ThoiGian, DaDoc
)
VALUES
(1, 1, NULL, N'LICH_HEN', N'Lich hen da duoc xac nhan', N'Lich hen bao duong luc 09:00 ngay 18/09/2026 da duoc gara xac nhan.', '2026-09-17T15:00:00', 1),
(1, NULL, 2, N'BAO_GIA', N'Bao gia da san sang', N'Bao gia cho phieu sua chua #2 da duoc lap va cho khach hang xac nhan.', '2026-09-18T09:22:00', 1),
(3, 3, NULL, N'LICH_HEN', N'Lich hen cho xac nhan', N'Gara da tiep nhan yeu cau dat lich ngay 19/09/2026.', '2026-09-18T08:00:00', 0),
(4, 4, NULL, N'NHAC_BAO_DUONG', N'Nhac lich bao duong', N'Quy khach co lich thay dau dong co luc 08:30 ngay 20/09/2026.', '2026-09-18T08:05:00', 0);
GO

-- Vi du kiem ke: ton thuc te loc dieu hoa trung voi he thong.
EXEC dbo.sp_KiemKeTonKho 7, 15, N'Kiem ke dinh ky - ton thuc te khop voi he thong';
GO

-- ============================================================
-- 14. CAC TRUY VAN KIEM TRA NHANH SAU KHI CHAY SCRIPT
-- ============================================================

-- 1) Ton kho + trang thai ton kho
SELECT
    pt.MaPhuTung,
    pt.TenPhuTung,
    pt.SoLuongTon,
    pt.MucTonToiThieu,
    dbo.fn_TrangThaiTonKho(pt.MaPhuTung) AS TrangThaiTonKho
FROM PhuTung pt
ORDER BY pt.MaPhuTung;
GO

-- 2) Bao gia va tong tien da duoc trigger cap nhat
SELECT MaBaoGia, MaPhieuSuaChua, TongTien, TrangThai, NgayXacNhan
FROM BaoGia
ORDER BY MaBaoGia;
GO

-- 3) Lich su bien dong kho
SELECT
    bd.MaBienDong,
    bd.MaPhuTung,
    pt.TenPhuTung,
    bd.LoaiBienDong,
    bd.SoLuong,
    bd.SoLuongTruoc,
    bd.SoLuongSau,
    bd.ThoiGian,
    bd.GhiChu
FROM BienDongKho bd
INNER JOIN PhuTung pt ON pt.MaPhuTung = bd.MaPhuTung
ORDER BY bd.MaBienDong;
GO

-- 4) Hoa don + so tien da thanh toan
SELECT
    hd.MaHoaDon,
    hd.MaPhieuSuaChua,
    hd.TongTien,
    dbo.fn_TongDaThanhToan(hd.MaHoaDon) AS DaThanhToan,
    hd.TrangThai
FROM HoaDon hd
ORDER BY hd.MaHoaDon;
GO
