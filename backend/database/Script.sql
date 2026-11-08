-- ============================================================
-- DATABASE: QuanLyGaraOTo
-- SQL Server
-- De tai: "Xay dung he thong quan ly gara sua chua o to"
-- Ban cap nhat:
--   1) Bo thuoc tinh ChuyenMon cua KyThuatVien.
--   2) Bo sung PhieuNhapKho / ChiTietPhieuNhap theo nghiep vu nhap kho BUC05.a.
--   3) Bo sung xac nhan su dung phu tung truoc khi tru ton kho.
--   4) Bo sung FUNCTION / PROCEDURE / TRIGGER phuc vu nghiep vu thuc te.
--   5) Chi khoi tao schema; khong chen tai khoan hoac du lieu nghiep vu mau.
-- Du lieu test, neu can, phai chay rieng va khong thuoc luong khoi tao van hanh.
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
    DiaChi             NVARCHAR(255) NULL,
    TrangThai          BIT NOT NULL CONSTRAINT DF_KhachHang_TrangThai DEFAULT 1
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
    TrangThai          BIT NOT NULL CONSTRAINT DF_DichVu_TrangThai DEFAULT 1,

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

    BEGIN TRY
        BEGIN TRAN;

    DECLARE @TongHoaDon DECIMAL(18,2);
    DECLARE @DaThanhToan DECIMAL(18,2);

    SELECT @TongHoaDon = TongTien
    FROM HoaDon WITH (UPDLOCK, HOLDLOCK)
    WHERE MaHoaDon = @MaHoaDon;

    IF @TongHoaDon IS NULL
        THROW 50041, N'Hoa don khong ton tai.', 1;

    SET @DaThanhToan = dbo.fn_TongDaThanhToan(@MaHoaDon);

    IF @DaThanhToan + @SoTien > @TongHoaDon
        THROW 50042, N'So tien thanh toan vuot qua so tien con lai cua hoa don.', 1;



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
