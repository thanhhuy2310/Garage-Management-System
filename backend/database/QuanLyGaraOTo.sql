-- ============================================================
-- DATABASE: QuanLyGaraOTo
-- SQL Server
-- Sinh từ mô hình lớp phân tích / thiết kế của đề tài
-- "Xây dựng hệ thống quản lý gara sửa chữa ô tô"
-- ============================================================

IF DB_ID(N'QuanLyGaraOTo') IS NULL
BEGIN
    CREATE DATABASE QuanLyGaraOTo;
END
GO

USE QuanLyGaraOTo;
GO

-- ============================================================
-- 1. KHACH HANG - NHAN VIEN - TAI KHOAN
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

-- Kế thừa theo kiểu: lớp con dùng cùng khóa chính với lớp cha.
CREATE TABLE KyThuatVien (
    MaNhanVien         INT PRIMARY KEY,
    ChuyenMon          NVARCHAR(150) NULL,

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

    -- Một tài khoản thuộc về khách hàng hoặc nhân viên, không đồng thời cả hai.
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

-- Hỗ trợ FK kép để đảm bảo lịch hẹn dùng đúng xe của khách hàng.
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

-- [ĐỀ XUẤT BỔ SUNG]
-- Đề cương yêu cầu "phân công kỹ thuật viên" nhưng không chốt 1 hay nhiều KTV/phiếu.
-- Dùng bảng liên kết để không khóa thiết kế vào giả định chỉ có 1 KTV.
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
    TongTien           DECIMAL(18,2) NOT NULL,
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

    -- Một dòng báo giá thuộc dịch vụ hoặc phụ tùng.
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
-- 6. XUAT KHO - LICH SU BIEN DONG KHO
-- ============================================================

CREATE TABLE PhieuXuatKho (
    MaPhieuXuat        INT IDENTITY(1,1) PRIMARY KEY,
    MaPhieuSuaChua     INT NULL,
    NgayXuat           DATETIME2(0) NOT NULL,
    LyDo               NVARCHAR(500) NOT NULL,

    CONSTRAINT FK_PhieuXuatKho_PhieuSuaChua
        FOREIGN KEY (MaPhieuSuaChua)
        REFERENCES PhieuSuaChua(MaPhieuSuaChua)
);
GO

CREATE TABLE ChiTietPhieuXuat (
    MaPhieuXuat        INT NOT NULL,
    MaPhuTung          INT NOT NULL,
    SoLuong            INT NOT NULL,
    DonGia             DECIMAL(18,2) NULL,

    CONSTRAINT PK_ChiTietPhieuXuat
        PRIMARY KEY (MaPhieuXuat, MaPhuTung),

    CONSTRAINT FK_ChiTietPhieuXuat_PhieuXuat
        FOREIGN KEY (MaPhieuXuat)
        REFERENCES PhieuXuatKho(MaPhieuXuat),

    CONSTRAINT FK_ChiTietPhieuXuat_PhuTung
        FOREIGN KEY (MaPhuTung)
        REFERENCES PhuTung(MaPhuTung),

    CONSTRAINT CK_ChiTietPhieuXuat_SoLuong CHECK (SoLuong > 0),
    CONSTRAINT CK_ChiTietPhieuXuat_DonGia CHECK (DonGia IS NULL OR DonGia >= 0)
);
GO

-- Bảng này được thêm vì đề cương yêu cầu "lịch sử biến động kho".
-- Không cần tạo riêng Phiếu nhập kho nếu khảo sát gara chưa xác nhận biểu mẫu này.
CREATE TABLE BienDongKho (
    MaBienDong         BIGINT IDENTITY(1,1) PRIMARY KEY,
    MaPhuTung          INT NOT NULL,
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

    CONSTRAINT FK_BienDongKho_PhieuXuat
        FOREIGN KEY (MaPhieuXuat)
        REFERENCES PhieuXuatKho(MaPhieuXuat),

    CONSTRAINT CK_BienDongKho_Loai
        CHECK (LoaiBienDong IN (N'NHAP', N'XUAT', N'KIEM_KE')),

    CONSTRAINT CK_BienDongKho_SoLuong CHECK (SoLuong > 0),
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
-- 9. INDEX THƯỜNG DÙNG
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

CREATE INDEX IX_BienDongKho_MaPhuTung_ThoiGian
ON BienDongKho(MaPhuTung, ThoiGian);
GO

CREATE INDEX IX_ThongBao_MaKhachHang_DaDoc
ON ThongBao(MaKhachHang, DaDoc);
GO

-- ============================================================
-- GHI CHÚ THIẾT KẾ
-- ============================================================
-- 1. Không tạo bảng LichSuSuaChua riêng:
--    lịch sử được truy vấn từ PhieuSuaChua -> PhieuTiepNhan -> Xe.
--
-- 2. Không tạo PhieuNhapKho ở bản chính:
--    tài liệu yêu cầu nghiệp vụ nhập kho nhưng chưa xác nhận biểu mẫu Phiếu nhập.
--    Nhập kho được ghi qua BienDongKho với LoaiBienDong = 'NHAP'.
--
-- 3. Không tạo trigger tự động trừ tồn ngay khi lập Phiếu xuất:
--    đề cương quy định tồn kho cập nhật khi KTV xác nhận sử dụng/thay thế phụ tùng.
--    Nên xử lý bằng Stored Procedure / service sau khi chốt quy trình xác nhận.
--
-- 4. PhanCongKyThuatVien là đề xuất bổ sung để hỗ trợ trường hợp
--    một Phiếu sửa chữa có thể có nhiều KTV; nếu khảo sát xác nhận mỗi phiếu chỉ 1 KTV,
--    có thể thay bằng MaKyThuatVien trực tiếp trong PhieuSuaChua.
-- ============================================================
