-- TV3-TUAN8
-- ============================================================
-- V002 - Tuan 8 (TV3): kho phu tung - thuc dung & kiem ke co phe duyet
-- Chay MOT LAN tren database QuanLyGaraOTo da tao bang QuanLyGaraOTo.sql (+ V001).
-- Script idempotent: chay lai khong loi, khong mat du lieu.
--
-- 1. ChiTietPhieuXuat: them SoLuongThucDung, SoLuongHoanTra (giu nguyen SoLuong = so luong cap phat).
-- 2. Tao PhieuKiemKe / ChiTietKiemKe (kiem ke co phe duyet).
-- 3. Sua sp_XacNhanSuDungPhuTung: tru ton theo SO LUONG THUC DUNG, khong theo so cap phat.
-- 4. Sua sp_KiemKeTonKho: chi GHI NHAN kiem ke, KHONG cap nhat ton (chi MANAGER duyet qua ung dung).
-- Khong doi ten bang/cot cu. Khong them trigger/function/job.
-- ============================================================
USE QuanLyGaraOTo;
GO

-- ------------------------------------------------------------
-- 1. ChiTietPhieuXuat: thuc dung / hoan tra
-- ------------------------------------------------------------
IF COL_LENGTH('dbo.ChiTietPhieuXuat', 'SoLuongThucDung') IS NULL
    ALTER TABLE dbo.ChiTietPhieuXuat ADD SoLuongThucDung INT NULL;
IF COL_LENGTH('dbo.ChiTietPhieuXuat', 'SoLuongHoanTra') IS NULL
    ALTER TABLE dbo.ChiTietPhieuXuat ADD SoLuongHoanTra INT NULL;
GO

-- Dong da xac nhan theo ngu nghia cu (da tru du so cap phat): thuc dung = cap phat, hoan tra = 0.
UPDATE dbo.ChiTietPhieuXuat
SET SoLuongThucDung = SoLuong,
    SoLuongHoanTra = 0
WHERE DaXacNhanSuDung = 1
  AND SoLuongThucDung IS NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_ChiTietPhieuXuat_ThucDung')
    ALTER TABLE dbo.ChiTietPhieuXuat WITH CHECK ADD CONSTRAINT CK_ChiTietPhieuXuat_ThucDung
        CHECK (
            (DaXacNhanSuDung = 0 AND SoLuongThucDung IS NULL AND SoLuongHoanTra IS NULL)
            OR
            (DaXacNhanSuDung = 1
                AND SoLuongThucDung IS NOT NULL AND SoLuongHoanTra IS NOT NULL
                AND SoLuongThucDung >= 0 AND SoLuongThucDung <= SoLuong
                AND SoLuongHoanTra = SoLuong - SoLuongThucDung)
        );
GO

-- ------------------------------------------------------------
-- 2. Kiem ke co phe duyet
-- ------------------------------------------------------------
IF OBJECT_ID(N'dbo.PhieuKiemKe', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PhieuKiemKe (
        MaPhieuKiemKe     INT IDENTITY(1,1) PRIMARY KEY,
        NgayKiemKe        DATETIME2(0) NOT NULL,
        MaNhanVienKiemKe  INT NOT NULL,
        MaNhanVienDuyet   INT NULL,
        NgayDuyet         DATETIME2(0) NULL,
        TrangThai         NVARCHAR(30) NOT NULL,
        GhiChu            NVARCHAR(500) NULL,
        LyDoDuyet         NVARCHAR(500) NULL,

        CONSTRAINT FK_PhieuKiemKe_NhanVienKiemKe
            FOREIGN KEY (MaNhanVienKiemKe) REFERENCES dbo.NhanVien(MaNhanVien),
        CONSTRAINT FK_PhieuKiemKe_NhanVienDuyet
            FOREIGN KEY (MaNhanVienDuyet) REFERENCES dbo.NhanVien(MaNhanVien),
        CONSTRAINT CK_PhieuKiemKe_TrangThai
            CHECK (TrangThai IN (N'DANG_KIEM_KE', N'CHO_PHE_DUYET', N'DA_HOAN_TAT', N'DA_TU_CHOI')),
        -- Nguoi duyet va ngay duyet luon di cung nhau.
        CONSTRAINT CK_PhieuKiemKe_Duyet
            CHECK ((MaNhanVienDuyet IS NULL AND NgayDuyet IS NULL)
                   OR (MaNhanVienDuyet IS NOT NULL AND NgayDuyet IS NOT NULL))
    );
END
GO

IF OBJECT_ID(N'dbo.ChiTietKiemKe', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ChiTietKiemKe (
        MaPhieuKiemKe     INT NOT NULL,
        MaPhuTung         INT NOT NULL,
        SoLuongHeThong    INT NOT NULL,
        SoLuongThucTe     INT NULL,
        ChenhLech AS (SoLuongThucTe - SoLuongHeThong) PERSISTED,
        LyDo              NVARCHAR(500) NULL,
        DaDuyetDieuChinh  BIT NOT NULL CONSTRAINT DF_ChiTietKiemKe_DaDuyet DEFAULT 0,

        CONSTRAINT PK_ChiTietKiemKe PRIMARY KEY (MaPhieuKiemKe, MaPhuTung),
        CONSTRAINT FK_ChiTietKiemKe_PhieuKiemKe
            FOREIGN KEY (MaPhieuKiemKe) REFERENCES dbo.PhieuKiemKe(MaPhieuKiemKe),
        CONSTRAINT FK_ChiTietKiemKe_PhuTung
            FOREIGN KEY (MaPhuTung) REFERENCES dbo.PhuTung(MaPhuTung),
        CONSTRAINT CK_ChiTietKiemKe_SoLuongHeThong CHECK (SoLuongHeThong >= 0),
        CONSTRAINT CK_ChiTietKiemKe_SoLuongThucTe CHECK (SoLuongThucTe IS NULL OR SoLuongThucTe >= 0)
    );
END
GO

-- ------------------------------------------------------------
-- 3. sp_XacNhanSuDungPhuTung: tru ton theo SO LUONG THUC DUNG
--    @SoLuongThucDung bo trong (NULL) = dung du so cap phat (tuong thich cac loi goi cu).
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_XacNhanSuDungPhuTung
    @MaPhieuXuat INT,
    @MaPhuTung INT,
    @MaKyThuatVien INT,
    @SoLuongThucDung INT = NULL
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

    IF @SoLuongThucDung IS NULL
        SET @SoLuongThucDung = @SoLuong;

    IF @SoLuongThucDung < 0 OR @SoLuongThucDung > @SoLuong
        THROW 50017, N'So luong thuc dung phai tu 0 den so luong cap phat.', 1;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @TonTruoc INT;
        DECLARE @TonSau INT;
        DECLARE @TongThucDung INT;

        SELECT @TonTruoc = SoLuongTon
        FROM PhuTung WITH (UPDLOCK, HOLDLOCK)
        WHERE MaPhuTung = @MaPhuTung;

        IF @TonTruoc < @SoLuongThucDung
            THROW 50015, N'So luong ton kho khong du de xac nhan su dung.', 1;

        SET @TonSau = @TonTruoc - @SoLuongThucDung;

        -- Chi tru ton theo so luong THUC DUNG (phan con lai la hoan tra, ton khong doi).
        IF @SoLuongThucDung > 0
            UPDATE PhuTung
            SET SoLuongTon = @TonSau
            WHERE MaPhuTung = @MaPhuTung;

        UPDATE ChiTietPhieuXuat
        SET
            DaXacNhanSuDung = 1,
            NgayXacNhan = SYSDATETIME(),
            MaKyThuatVienXacNhan = @MaKyThuatVien,
            SoLuongThucDung = @SoLuongThucDung,
            SoLuongHoanTra = @SoLuong - @SoLuongThucDung
        WHERE MaPhieuXuat = @MaPhieuXuat
          AND MaPhuTung = @MaPhuTung;

        -- ChiTietPhuTung.SoLuong = tong THUC DUNG da xac nhan cua (phieu sua chua, phu tung).
        -- Neu tong = 0 thi khong dong vao dong san co (rang buoc SoLuong > 0).
        SELECT @TongThucDung = COALESCE(SUM(ct.SoLuongThucDung), 0)
        FROM ChiTietPhieuXuat ct
        INNER JOIN PhieuXuatKho px ON px.MaPhieuXuat = ct.MaPhieuXuat
        WHERE px.MaPhieuSuaChua = @MaPhieuSuaChua
          AND ct.MaPhuTung = @MaPhuTung
          AND ct.DaXacNhanSuDung = 1;

        IF @TongThucDung > 0
        BEGIN
            IF EXISTS (
                SELECT 1
                FROM ChiTietPhuTung
                WHERE MaPhieuSuaChua = @MaPhieuSuaChua
                  AND MaPhuTung = @MaPhuTung
            )
                UPDATE ChiTietPhuTung
                SET SoLuong = @TongThucDung,
                    DonGia = @DonGia
                WHERE MaPhieuSuaChua = @MaPhieuSuaChua
                  AND MaPhuTung = @MaPhuTung;
            ELSE
                INSERT INTO ChiTietPhuTung (MaPhieuSuaChua, MaPhuTung, SoLuong, DonGia)
                VALUES (@MaPhieuSuaChua, @MaPhuTung, @TongThucDung, @DonGia);
        END

        -- BienDongKho.SoLuong (>0 theo CK_BienDongKho_SoLuong) = so luong thuc dung; thuc dung = 0 thi khong co bien dong.
        IF @SoLuongThucDung > 0
            INSERT INTO BienDongKho (
                MaPhuTung, MaPhieuNhap, MaPhieuXuat,
                ThoiGian, LoaiBienDong, SoLuong,
                SoLuongTruoc, SoLuongSau, GhiChu
            )
            VALUES (
                @MaPhuTung, NULL, @MaPhieuXuat,
                SYSDATETIME(), N'XUAT', @SoLuongThucDung,
                @TonTruoc, @TonSau,
                N'KTV xac nhan thuc dung ' + CONVERT(NVARCHAR(12), @SoLuongThucDung)
                    + N'/' + CONVERT(NVARCHAR(12), @SoLuong)
                    + N' (hoan tra ' + CONVERT(NVARCHAR(12), @SoLuong - @SoLuongThucDung) + N')'
            );

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- ------------------------------------------------------------
-- 4. sp_KiemKeTonKho: chi GHI NHAN kiem ke mot phu tung, KHONG bao gio cap nhat PhuTung.SoLuongTon.
--    Khong chenh lech -> DA_HOAN_TAT; co chenh lech -> CHO_PHE_DUYET (MANAGER duyet qua ung dung).
--    @MaNhanVienKiemKe bat buoc (cot NOT NULL); tham so de mac dinh NULL de giu chu ky goi cu cua seed.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_KiemKeTonKho
    @MaPhuTung INT,
    @SoLuongThucTe INT,
    @GhiChu NVARCHAR(500) = NULL,
    @MaNhanVienKiemKe INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @SoLuongThucTe < 0
        THROW 50020, N'So luong thuc te khong duoc am.', 1;

    IF NOT EXISTS (SELECT 1 FROM PhuTung WHERE MaPhuTung = @MaPhuTung)
        THROW 50021, N'Phu tung khong ton tai.', 1;

    IF @MaNhanVienKiemKe IS NULL
        THROW 50022, N'Can chi dinh nhan vien kiem ke.', 1;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @TonHeThong INT;
        DECLARE @MaPhieuKiemKe INT;

        SELECT @TonHeThong = SoLuongTon
        FROM PhuTung WITH (UPDLOCK, HOLDLOCK)
        WHERE MaPhuTung = @MaPhuTung;

        INSERT INTO PhieuKiemKe (NgayKiemKe, MaNhanVienKiemKe, TrangThai, GhiChu)
        VALUES (
            SYSDATETIME(), @MaNhanVienKiemKe,
            CASE WHEN @SoLuongThucTe = @TonHeThong THEN N'DA_HOAN_TAT' ELSE N'CHO_PHE_DUYET' END,
            COALESCE(@GhiChu, N'Kiem ke ton kho')
        );
        SET @MaPhieuKiemKe = SCOPE_IDENTITY();

        INSERT INTO ChiTietKiemKe (MaPhieuKiemKe, MaPhuTung, SoLuongHeThong, SoLuongThucTe)
        VALUES (@MaPhieuKiemKe, @MaPhuTung, @TonHeThong, @SoLuongThucTe);

        -- Co chenh lech: ton giu nguyen cho den khi MANAGER phe duyet.
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO
