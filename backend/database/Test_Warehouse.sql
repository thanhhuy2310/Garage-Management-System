-- TV3-TUAN8
-- ============================================================
-- Test_Warehouse.sql - kho phu tung (Tuan 8 - TV3)
-- YEU CAU: da chay QuanLyGaraOTo.sql va migrations/V002__warehouse_actual_used_and_stock_check.sql.
-- Script KHONG bao boc mot transaction: cac procedure co THROW trong TRAN se ROLLBACK ca transaction ngoai.
-- Vi vay du lieu test dung nhan 'TEST-WH' va duoc don sach o cuoi script.
-- ============================================================
USE QuanLyGaraOTo;
GO

SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.PhieuKiemKe', N'U') IS NULL OR COL_LENGTH('dbo.ChiTietPhieuXuat', 'SoLuongThucDung') IS NULL
BEGIN
    PRINT N'Chua chay migration V002. Dung lai.';
    RETURN;
END;

DECLARE @Result TABLE (Id INT IDENTITY(1,1), TestName NVARCHAR(200), Detail NVARCHAR(400), Result NVARCHAR(4));

DECLARE @kho INT, @nv INT, @order INT, @ktv INT;
DECLARE @pt INT, @phieuNhap INT, @phieuXuat INT, @phieuXuat2 INT, @pk INT;
DECLARE @ton INT, @ton2 INT, @n INT, @n2 INT, @err INT, @msg NVARCHAR(400);

SELECT TOP 1 @kho = MaKho FROM Kho ORDER BY MaKho;
SELECT TOP 1 @nv = MaNhanVien FROM NhanVien ORDER BY MaNhanVien;

-- Phieu sua chua dang sua, co phan cong KTV + bao gia da xac nhan (seed co san phieu 1, 2).
-- Khong doi trang thai phieu sua chua (tranh kich hoat trigger thong bao hoan tat).
SELECT TOP 1 @order = pc.MaPhieuSuaChua, @ktv = pc.MaKyThuatVien
FROM PhanCongKyThuatVien pc
INNER JOIN PhieuSuaChua ps ON ps.MaPhieuSuaChua = pc.MaPhieuSuaChua AND ps.TrangThai IN (N'DANG_SUA', N'CHO_PHU_TUNG')
INNER JOIN BaoGia bg ON bg.MaPhieuSuaChua = pc.MaPhieuSuaChua AND bg.TrangThai = N'DA_XAC_NHAN'
ORDER BY pc.MaPhieuSuaChua;

IF @kho IS NULL OR @nv IS NULL OR @order IS NULL
BEGIN
    PRINT N'Thieu du lieu mau: can Kho, NhanVien va 1 phieu sua chua DANG_SUA/CHO_PHU_TUNG co phan cong KTV + bao gia da xac nhan.';
    RETURN;
END;

INSERT INTO PhuTung (MaKho, TenPhuTung, HangSanXuat, DonGia, MucTonToiThieu)
VALUES (@kho, N'TEST-WH phu tung', N'TEST-WH', 100000, 5);
SET @pt = SCOPE_IDENTITY();

INSERT INTO PhieuNhapKho (NgayNhap, NhaCungCap, MaNhanVienKho, GhiChu)
VALUES (SYSDATETIME(), N'TEST-WH nha cung cap', @nv, N'TEST-WH');
SET @phieuNhap = SCOPE_IDENTITY();

-- T1: nhap kho 10 -> ton tang dung 1 lan, co bien dong NHAP
BEGIN TRY
    EXEC dbo.sp_ThemChiTietPhieuNhap @phieuNhap, @pt, 10, 100000;
    SELECT @ton = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
    SELECT @n = COUNT(*) FROM BienDongKho WHERE MaPhuTung = @pt AND MaPhieuNhap = @phieuNhap AND LoaiBienDong = N'NHAP' AND SoLuong = 10 AND SoLuongTruoc = 0 AND SoLuongSau = 10;
    INSERT INTO @Result VALUES (N'T1 nhap kho tang ton dung 1 lan', N'ton=' + CAST(@ton AS NVARCHAR(10)) + N', so bien dong NHAP=' + CAST(@n AS NVARCHAR(10)),
        CASE WHEN @ton = 10 AND @n = 1 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T1 nhap kho', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T2: nhap trung phu tung trong cung phieu -> 50005, ton khong doi
SET @err = NULL;
BEGIN TRY
    EXEC dbo.sp_ThemChiTietPhieuNhap @phieuNhap, @pt, 5, 100000;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
SELECT @ton = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
INSERT INTO @Result VALUES (N'T2 nhap trung phu tung trong phieu', N'loi=' + COALESCE(CAST(@err AS NVARCHAR(10)), N'khong loi') + N', ton=' + CAST(@ton AS NVARCHAR(10)),
    CASE WHEN @err = 50005 AND @ton = 10 THEN 'PASS' ELSE 'FAIL' END);

-- T3: nhap so luong 0 -> 50001
SET @err = NULL;
BEGIN TRY
    EXEC dbo.sp_ThemChiTietPhieuNhap @phieuNhap, @pt, 0, 100000;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
INSERT INTO @Result VALUES (N'T3 nhap so luong = 0', N'loi=' + COALESCE(CAST(@err AS NVARCHAR(10)), N'khong loi'), CASE WHEN @err = 50001 THEN 'PASS' ELSE 'FAIL' END);

-- T4: phu tung khong ton tai -> 50004
SET @err = NULL;
BEGIN TRY
    EXEC dbo.sp_ThemChiTietPhieuNhap @phieuNhap, -1, 1, 1;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
INSERT INTO @Result VALUES (N'T4 nhap phu tung khong ton tai', N'loi=' + COALESCE(CAST(@err AS NVARCHAR(10)), N'khong loi'), CASE WHEN @err = 50004 THEN 'PASS' ELSE 'FAIL' END);

-- T5: cap phat 5 (tao phieu xuat) KHONG giam ton, KHONG co bien dong
INSERT INTO PhieuXuatKho (MaPhieuSuaChua, MaNhanVienKho, MaKyThuatVienYeuCau, NgayXuat, LyDo)
VALUES (@order, @nv, @ktv, SYSDATETIME(), N'TEST-WH cap phat');
SET @phieuXuat = SCOPE_IDENTITY();
INSERT INTO ChiTietPhieuXuat (MaPhieuXuat, MaPhuTung, SoLuong, DonGia) VALUES (@phieuXuat, @pt, 5, 100000);
SELECT @ton = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
SELECT @n = COUNT(*) FROM BienDongKho WHERE MaPhuTung = @pt AND MaPhieuXuat = @phieuXuat;
INSERT INTO @Result VALUES (N'T5 cap phat khong giam ton', N'ton=' + CAST(@ton AS NVARCHAR(10)) + N', bien dong=' + CAST(@n AS NVARCHAR(10)),
    CASE WHEN @ton = 10 AND @n = 0 THEN 'PASS' ELSE 'FAIL' END);

-- T6: thuc dung 6 > cap phat 5 -> 50017, ton khong doi, chua xac nhan
SET @err = NULL;
BEGIN TRY
    EXEC dbo.sp_XacNhanSuDungPhuTung @phieuXuat, @pt, @ktv, 6;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
SELECT @ton = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
SELECT @n = DaXacNhanSuDung FROM ChiTietPhieuXuat WHERE MaPhieuXuat = @phieuXuat AND MaPhuTung = @pt;
INSERT INTO @Result VALUES (N'T6 thuc dung > cap phat bi tu choi', N'loi=' + COALESCE(CAST(@err AS NVARCHAR(10)), N'khong loi') + N', ton=' + CAST(@ton AS NVARCHAR(10)),
    CASE WHEN @err = 50017 AND @ton = 10 AND @n = 0 THEN 'PASS' ELSE 'FAIL' END);

-- T7: thuc dung am -> 50017
SET @err = NULL;
BEGIN TRY
    EXEC dbo.sp_XacNhanSuDungPhuTung @phieuXuat, @pt, @ktv, -1;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
INSERT INTO @Result VALUES (N'T7 thuc dung am', N'loi=' + COALESCE(CAST(@err AS NVARCHAR(10)), N'khong loi'), CASE WHEN @err = 50017 THEN 'PASS' ELSE 'FAIL' END);

-- T8: cap phat 5, thuc dung 3 -> ton 10 -> 7, hoan tra 2, ChiTietPhuTung = 3, bien dong XUAT = 3
BEGIN TRY
    EXEC dbo.sp_XacNhanSuDungPhuTung @phieuXuat, @pt, @ktv, 3;
    SELECT @ton = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
    SELECT @n = SoLuongHoanTra FROM ChiTietPhieuXuat WHERE MaPhieuXuat = @phieuXuat AND MaPhuTung = @pt AND SoLuongThucDung = 3 AND DaXacNhanSuDung = 1;
    SELECT @n2 = SoLuong FROM ChiTietPhuTung WHERE MaPhieuSuaChua = @order AND MaPhuTung = @pt;
    SELECT @err = COUNT(*) FROM BienDongKho WHERE MaPhuTung = @pt AND MaPhieuXuat = @phieuXuat AND LoaiBienDong = N'XUAT' AND SoLuong = 3 AND SoLuongTruoc = 10 AND SoLuongSau = 7;
    INSERT INTO @Result VALUES (N'T8 cap phat 5 thuc dung 3: ton -3, hoan tra 2, ChiTietPhuTung = 3, bien dong XUAT = 3',
        N'ton=' + CAST(@ton AS NVARCHAR(10)) + N', hoan tra=' + COALESCE(CAST(@n AS NVARCHAR(10)), N'null') + N', ChiTietPhuTung=' + COALESCE(CAST(@n2 AS NVARCHAR(10)), N'null') + N', bien dong=' + CAST(@err AS NVARCHAR(10)),
        CASE WHEN @ton = 7 AND @n = 2 AND @n2 = 3 AND @err = 1 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T8 xac nhan thuc dung', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T9: xac nhan lan 2 -> 50012, ton khong doi
SET @err = NULL;
BEGIN TRY
    EXEC dbo.sp_XacNhanSuDungPhuTung @phieuXuat, @pt, @ktv, 3;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
SELECT @ton = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
INSERT INTO @Result VALUES (N'T9 xac nhan lan 2 bi tu choi', N'loi=' + COALESCE(CAST(@err AS NVARCHAR(10)), N'khong loi') + N', ton=' + CAST(@ton AS NVARCHAR(10)),
    CASE WHEN @err = 50012 AND @ton = 7 THEN 'PASS' ELSE 'FAIL' END);

-- T10: thuc dung 0 -> ton khong doi, hoan tra = cap phat, khong co bien dong XUAT moi
INSERT INTO PhieuXuatKho (MaPhieuSuaChua, MaNhanVienKho, MaKyThuatVienYeuCau, NgayXuat, LyDo)
VALUES (@order, @nv, @ktv, SYSDATETIME(), N'TEST-WH cap phat 2');
SET @phieuXuat2 = SCOPE_IDENTITY();
INSERT INTO ChiTietPhieuXuat (MaPhieuXuat, MaPhuTung, SoLuong, DonGia) VALUES (@phieuXuat2, @pt, 2, 100000);
BEGIN TRY
    EXEC dbo.sp_XacNhanSuDungPhuTung @phieuXuat2, @pt, @ktv, 0;
    SELECT @ton = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
    SELECT @n = SoLuongHoanTra FROM ChiTietPhieuXuat WHERE MaPhieuXuat = @phieuXuat2 AND MaPhuTung = @pt AND SoLuongThucDung = 0 AND DaXacNhanSuDung = 1;
    SELECT @n2 = COUNT(*) FROM BienDongKho WHERE MaPhieuXuat = @phieuXuat2;
    INSERT INTO @Result VALUES (N'T10 thuc dung 0: ton khong doi, hoan tra toan bo, khong bien dong',
        N'ton=' + CAST(@ton AS NVARCHAR(10)) + N', hoan tra=' + COALESCE(CAST(@n AS NVARCHAR(10)), N'null') + N', bien dong=' + CAST(@n2 AS NVARCHAR(10)),
        CASE WHEN @ton = 7 AND @n = 2 AND @n2 = 0 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T10 thuc dung 0', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T11: ton khong du thuc dung -> 50015, rollback (ton va trang thai khong doi)
INSERT INTO PhieuXuatKho (MaPhieuSuaChua, MaNhanVienKho, MaKyThuatVienYeuCau, NgayXuat, LyDo)
VALUES (@order, @nv, @ktv, SYSDATETIME(), N'TEST-WH cap phat 3');
DECLARE @phieuXuat3 INT = SCOPE_IDENTITY();
INSERT INTO ChiTietPhieuXuat (MaPhieuXuat, MaPhuTung, SoLuong, DonGia) VALUES (@phieuXuat3, @pt, 4, 100000);
UPDATE PhuTung SET SoLuongTon = 1 WHERE MaPhuTung = @pt;
SET @err = NULL;
BEGIN TRY
    EXEC dbo.sp_XacNhanSuDungPhuTung @phieuXuat3, @pt, @ktv, 4;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
SELECT @ton = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
SELECT @n = DaXacNhanSuDung FROM ChiTietPhieuXuat WHERE MaPhieuXuat = @phieuXuat3 AND MaPhuTung = @pt;
INSERT INTO @Result VALUES (N'T11 ton khong du thuc dung: rollback', N'loi=' + COALESCE(CAST(@err AS NVARCHAR(10)), N'khong loi') + N', ton=' + CAST(@ton AS NVARCHAR(10)),
    CASE WHEN @err = 50015 AND @ton = 1 AND @n = 0 THEN 'PASS' ELSE 'FAIL' END);
UPDATE PhuTung SET SoLuongTon = 7 WHERE MaPhuTung = @pt;

-- T12: rang buoc DB: hoan tra khong khop thuc dung bi CK_ChiTietPhieuXuat_ThucDung chan
SET @err = NULL;
BEGIN TRY
    UPDATE ChiTietPhieuXuat
    SET DaXacNhanSuDung = 1, NgayXacNhan = SYSDATETIME(), MaKyThuatVienXacNhan = @ktv, SoLuongThucDung = 1, SoLuongHoanTra = 1
    WHERE MaPhieuXuat = @phieuXuat3 AND MaPhuTung = @pt;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    SET @msg = ERROR_MESSAGE();
END CATCH;
INSERT INTO @Result VALUES (N'T12 hoan tra khong khop thuc dung bi CK chan', COALESCE(@msg, N'khong loi'),
    CASE WHEN @err = 547 AND @msg LIKE '%CK_ChiTietPhieuXuat_ThucDung%' THEN 'PASS' ELSE 'FAIL' END);

-- T13: kiem ke co chenh lech -> CHO_PHE_DUYET, TON KHONG DOI, khong co bien dong KIEM_KE
SELECT @ton = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
BEGIN TRY
    EXEC dbo.sp_KiemKeTonKho @pt, 4, N'TEST-WH kiem ke lech', @nv;
    SELECT TOP 1 @pk = MaPhieuKiemKe FROM ChiTietKiemKe WHERE MaPhuTung = @pt ORDER BY MaPhieuKiemKe DESC;
    SELECT @ton2 = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
    SELECT @n = COUNT(*) FROM PhieuKiemKe WHERE MaPhieuKiemKe = @pk AND TrangThai = N'CHO_PHE_DUYET';
    SELECT @n2 = COUNT(*) FROM BienDongKho WHERE MaPhuTung = @pt AND LoaiBienDong = N'KIEM_KE';
    INSERT INTO @Result VALUES (N'T13 kiem ke lech: cho phe duyet, ton khong doi', N'ton truoc=' + CAST(@ton AS NVARCHAR(10)) + N', ton sau=' + CAST(@ton2 AS NVARCHAR(10)) + N', bien dong KIEM_KE=' + CAST(@n2 AS NVARCHAR(10)),
        CASE WHEN @ton = @ton2 AND @n = 1 AND @n2 = 0 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T13 kiem ke lech', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T14: kiem ke khop -> DA_HOAN_TAT, ton khong doi
BEGIN TRY
    EXEC dbo.sp_KiemKeTonKho @pt, 7, N'TEST-WH kiem ke khop', @nv;
    SELECT TOP 1 @pk = MaPhieuKiemKe FROM ChiTietKiemKe WHERE MaPhuTung = @pt ORDER BY MaPhieuKiemKe DESC;
    SELECT @ton2 = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
    SELECT @n = COUNT(*) FROM PhieuKiemKe WHERE MaPhieuKiemKe = @pk AND TrangThai = N'DA_HOAN_TAT';
    INSERT INTO @Result VALUES (N'T14 kiem ke khop: hoan tat, ton khong doi', N'ton=' + CAST(@ton2 AS NVARCHAR(10)),
        CASE WHEN @ton2 = 7 AND @n = 1 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T14 kiem ke khop', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T15: kiem ke so luong thuc te am -> 50020; thieu nhan vien -> 50022
SET @err = NULL;
BEGIN TRY
    EXEC dbo.sp_KiemKeTonKho @pt, -1, NULL, @nv;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
SELECT @n = CASE WHEN @err = 50020 THEN 1 ELSE 0 END;
SET @err = NULL;
BEGIN TRY
    EXEC dbo.sp_KiemKeTonKho @pt, 7;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
INSERT INTO @Result VALUES (N'T15 kiem ke: thuc te am (50020), thieu nhan vien (50022)', N'',
    CASE WHEN @n = 1 AND @err = 50022 THEN 'PASS' ELSE 'FAIL' END);

-- T16: rang buoc trang thai kiem ke
SET @err = NULL;
BEGIN TRY
    UPDATE PhieuKiemKe SET TrangThai = N'KHONG_HOP_LE' WHERE MaPhieuKiemKe = @pk;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
INSERT INTO @Result VALUES (N'T16 trang thai kiem ke khong hop le bi CK chan', N'loi=' + COALESCE(CAST(@err AS NVARCHAR(10)), N'khong loi'),
    CASE WHEN @err = 547 THEN 'PASS' ELSE 'FAIL' END);

SELECT Id, TestName, Result, Detail FROM @Result ORDER BY Id;
SELECT @n = COUNT(*) FROM @Result WHERE Result = 'FAIL';

-- ------------------------------------------------------------
-- DON DEP (thu tu nguoc khoa ngoai)
-- ------------------------------------------------------------
DELETE FROM ChiTietKiemKe WHERE MaPhuTung = @pt;
DELETE FROM PhieuKiemKe WHERE GhiChu LIKE N'TEST-WH%';
DELETE FROM BienDongKho WHERE MaPhuTung = @pt;
DELETE FROM ChiTietPhuTung WHERE MaPhieuSuaChua = @order AND MaPhuTung = @pt;
DELETE FROM ChiTietPhieuXuat WHERE MaPhuTung = @pt;
DELETE FROM PhieuXuatKho WHERE LyDo LIKE N'TEST-WH%';
DELETE FROM ChiTietPhieuNhap WHERE MaPhuTung = @pt;
DELETE FROM PhieuNhapKho WHERE GhiChu = N'TEST-WH';
DELETE FROM PhuTung WHERE MaPhuTung = @pt;

IF @n = 0
    PRINT N'TAT CA TEST KHO DEU PASS (da don dep du lieu test).';
ELSE
    PRINT N'CO ' + CAST(@n AS NVARCHAR(10)) + N' TEST FAIL. Xem bang ket qua o tren (du lieu test da duoc don dep).';
GO
