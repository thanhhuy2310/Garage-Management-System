-- TV3-TUAN8
-- ============================================================
-- V003 - Tuan 8 audit (TV3): chong xac nhan thuc dung trung khi hai yeu cau den dong thoi
-- Chay SAU V002. Idempotent (CREATE OR ALTER). Khong doi bang/cot, khong them trigger/job.
-- sp_XacNhanSuDungPhuTung: khoa dong ChiTietPhieuXuat (UPDLOCK, HOLDLOCK) va kiem tra lai
-- DaXacNhanSuDung trong transaction, giong cach UI/API Spring Boot khoa dong (PESSIMISTIC_WRITE).
-- ============================================================
USE QuanLyGaraOTo;
GO

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

        -- Khoa dong chi tiet xuat va kiem tra lai trang thai TRONG transaction:
        -- hai yeu cau xac nhan dong thoi cung mot chi tiet chi co mot yeu cau thanh cong.
        SELECT @DaXacNhan = DaXacNhanSuDung
        FROM ChiTietPhieuXuat WITH (UPDLOCK, HOLDLOCK)
        WHERE MaPhieuXuat = @MaPhieuXuat
          AND MaPhuTung = @MaPhuTung;

        IF @DaXacNhan = 1
            THROW 50012, N'Phu tung nay da duoc xac nhan su dung.', 1;

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
