-- TV3-TUAN7
-- ============================================================
-- Test_SpareParts.sql - rang buoc PhuTung + ChiTietDichVu/ChiTietPhuTung (Tuan 7 - TV3)
-- Chay trong SSMS sau khi tao database bang QuanLyGaraOTo.sql.
-- Toan bo du lieu test nam trong mot transaction va duoc ROLLBACK cuoi script.
-- Khong goi procedure nhap/xuat kho: script chi kiem tra rang buoc va xac nhan
-- them dong chi tiet KHONG lam doi SoLuongTon.
-- ============================================================
USE QuanLyGaraOTo;
GO

SET NOCOUNT ON;
SET XACT_ABORT OFF;

DECLARE @Result TABLE (
    Id       INT IDENTITY(1,1),
    TestName NVARCHAR(200),
    Detail   NVARCHAR(400),
    Result   NVARCHAR(4)
);

DECLARE @kho INT, @order INT, @dv INT, @pt INT, @before INT, @after INT, @n INT, @tt DECIMAL(18,2);

SELECT TOP 1 @kho = MaKho FROM Kho ORDER BY MaKho;
SELECT TOP 1 @order = MaPhieuSuaChua FROM PhieuSuaChua ORDER BY MaPhieuSuaChua;
SELECT TOP 1 @dv = MaDichVu FROM DichVu ORDER BY MaDichVu;

IF @kho IS NULL OR @order IS NULL OR @dv IS NULL
BEGIN
    PRINT N'Thieu du lieu mau (Kho / PhieuSuaChua / DichVu). Hay chay QuanLyGaraOTo.sql truoc.';
    RETURN;
END;

BEGIN TRAN;

-- T1: them phu tung hop le, SoLuongTon mac dinh 0
BEGIN TRY
    INSERT INTO PhuTung (MaKho, TenPhuTung, HangSanXuat, DonGia, MucTonToiThieu)
    VALUES (@kho, N'TEST Phu tung 1', N'NGK', 100000, 5);
    SET @pt = SCOPE_IDENTITY();
    SELECT @n = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
    INSERT INTO @Result VALUES (N'T1 them phu tung hop le (ton mac dinh 0)', N'SoLuongTon=' + CAST(@n AS NVARCHAR(10)),
        CASE WHEN @n = 0 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T1 them phu tung hop le', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T2: DonGia am -> CK_PhuTung_DonGia
BEGIN TRY
    INSERT INTO PhuTung (MaKho, TenPhuTung, DonGia) VALUES (@kho, N'TEST gia am', -1);
    INSERT INTO @Result VALUES (N'T2 DonGia am', N'Insert van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T2 DonGia am', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%CK_PhuTung_DonGia%' THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T3: MucTonToiThieu am -> CK_PhuTung_MucTonToiThieu
BEGIN TRY
    INSERT INTO PhuTung (MaKho, TenPhuTung, DonGia, MucTonToiThieu) VALUES (@kho, N'TEST muc ton am', 1, -1);
    INSERT INTO @Result VALUES (N'T3 MucTonToiThieu am', N'Insert van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T3 MucTonToiThieu am', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%CK_PhuTung_MucTonToiThieu%' THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T4: SoLuongTon am -> CK_PhuTung_SoLuongTon
BEGIN TRY
    INSERT INTO PhuTung (MaKho, TenPhuTung, DonGia, SoLuongTon) VALUES (@kho, N'TEST ton am', 1, -1);
    INSERT INTO @Result VALUES (N'T4 SoLuongTon am', N'Insert van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T4 SoLuongTon am', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%CK_PhuTung_SoLuongTon%' THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T5: MaKho khong ton tai -> FK_PhuTung_Kho
BEGIN TRY
    INSERT INTO PhuTung (MaKho, TenPhuTung, DonGia) VALUES (-1, N'TEST kho sai', 1);
    INSERT INTO @Result VALUES (N'T5 MaKho khong ton tai', N'Insert van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T5 MaKho khong ton tai', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%FK_PhuTung_Kho%' THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T6: them dong ChiTietPhuTung KHONG lam doi SoLuongTon, ThanhTien = SoLuong x DonGia
BEGIN TRY
    SELECT @before = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
    INSERT INTO ChiTietPhuTung (MaPhieuSuaChua, MaPhuTung, SoLuong, DonGia) VALUES (@order, @pt, 3, 100000);
    SELECT @after = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
    SELECT @tt = ThanhTien FROM ChiTietPhuTung WHERE MaPhieuSuaChua = @order AND MaPhuTung = @pt;
    INSERT INTO @Result VALUES (N'T6 them chi tiet phu tung khong doi ton, ThanhTien dung',
        N'ton truoc=' + CAST(@before AS NVARCHAR(10)) + N', ton sau=' + CAST(@after AS NVARCHAR(10)) + N', ThanhTien=' + CAST(@tt AS NVARCHAR(30)),
        CASE WHEN @before = @after AND @tt = 300000 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T6 them chi tiet phu tung', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T7: trung (phieu, phu tung) -> PK_ChiTietPhuTung
BEGIN TRY
    INSERT INTO ChiTietPhuTung (MaPhieuSuaChua, MaPhuTung, SoLuong, DonGia) VALUES (@order, @pt, 1, 100000);
    INSERT INTO @Result VALUES (N'T7 trung phu tung trong phieu', N'Insert van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T7 trung phu tung trong phieu', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() IN (2627, 2601) THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T8: SoLuong <= 0 -> CK_ChiTietPhuTung_SoLuong
BEGIN TRY
    INSERT INTO PhuTung (MaKho, TenPhuTung, DonGia) VALUES (@kho, N'TEST Phu tung 2', 1);
    INSERT INTO ChiTietPhuTung (MaPhieuSuaChua, MaPhuTung, SoLuong, DonGia) VALUES (@order, SCOPE_IDENTITY(), 0, 1);
    INSERT INTO @Result VALUES (N'T8 SoLuong = 0', N'Insert van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T8 SoLuong = 0', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%CK_ChiTietPhuTung_SoLuong%' THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T9: DonGia am tren ChiTietPhuTung -> CK_ChiTietPhuTung_DonGia
BEGIN TRY
    INSERT INTO PhuTung (MaKho, TenPhuTung, DonGia) VALUES (@kho, N'TEST Phu tung 3', 1);
    INSERT INTO ChiTietPhuTung (MaPhieuSuaChua, MaPhuTung, SoLuong, DonGia) VALUES (@order, SCOPE_IDENTITY(), 1, -1);
    INSERT INTO @Result VALUES (N'T9 DonGia am (chi tiet phu tung)', N'Insert van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T9 DonGia am (chi tiet phu tung)', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%CK_ChiTietPhuTung_DonGia%' THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T10: phieu sua chua khong ton tai -> FK_ChiTietPhuTung_PhieuSuaChua
BEGIN TRY
    INSERT INTO ChiTietPhuTung (MaPhieuSuaChua, MaPhuTung, SoLuong, DonGia) VALUES (-1, @pt, 1, 1);
    INSERT INTO @Result VALUES (N'T10 phieu sua chua khong ton tai', N'Insert van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T10 phieu sua chua khong ton tai', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%FK_ChiTietPhuTung_PhieuSuaChua%' THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T11: dong dich vu hop le, ThanhTien dung (dich vu dau tien chua co trong phieu thi moi them)
BEGIN TRY
    DELETE FROM ChiTietDichVu WHERE MaPhieuSuaChua = @order AND MaDichVu = @dv;
    INSERT INTO ChiTietDichVu (MaPhieuSuaChua, MaDichVu, SoLuong, DonGia) VALUES (@order, @dv, 2, 250000);
    SELECT @tt = ThanhTien FROM ChiTietDichVu WHERE MaPhieuSuaChua = @order AND MaDichVu = @dv;
    INSERT INTO @Result VALUES (N'T11 chi tiet dich vu hop le, ThanhTien dung', N'ThanhTien=' + CAST(@tt AS NVARCHAR(30)),
        CASE WHEN @tt = 500000 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T11 chi tiet dich vu hop le', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T12: SoLuong <= 0 tren ChiTietDichVu -> CK_ChiTietDichVu_SoLuong
BEGIN TRY
    UPDATE ChiTietDichVu SET SoLuong = 0 WHERE MaPhieuSuaChua = @order AND MaDichVu = @dv;
    INSERT INTO @Result VALUES (N'T12 SoLuong = 0 (chi tiet dich vu)', N'Update van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T12 SoLuong = 0 (chi tiet dich vu)', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%CK_ChiTietDichVu_SoLuong%' THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

SELECT Id, TestName, Result, Detail FROM @Result ORDER BY Id;

SELECT @n = COUNT(*) FROM @Result WHERE Result = 'FAIL';
IF @n = 0
    PRINT N'TAT CA TEST SPAREPART/REPAIR DETAIL DEU PASS.';
ELSE
    PRINT N'CO ' + CAST(@n AS NVARCHAR(10)) + N' TEST FAIL. Xem bang ket qua o tren.';

-- Khong de lai du lieu test (ke ca dong dich vu bi xoa/them o T11).
ROLLBACK TRAN;
GO
