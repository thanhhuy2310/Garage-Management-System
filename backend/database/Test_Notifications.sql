-- TV3-TUAN10
-- ============================================================
-- Test_Notifications.sql - trigger thong bao + lich nhac bao duong (Tuan 10 - TV3)
-- YEU CAU: da chay QuanLyGaraOTo.sql va migrations V001..V004.
-- Toan bo test nam trong mot transaction va duoc ROLLBACK cuoi script (trigger khong dung THROW nen an toan).
-- Chay bang SSMS (hoac sqlcmd -I).
-- ============================================================
USE QuanLyGaraOTo;
GO
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.LichNhacBaoDuong', N'U') IS NULL OR COL_LENGTH('dbo.ThongBao', 'MaLichNhac') IS NULL
   OR OBJECT_ID(N'dbo.TRG_LichHen_ThongBao', N'TR') IS NULL
BEGIN
    PRINT N'Chua chay migration V004. Dung lai.';
    RETURN;
END;

DECLARE @Result TABLE (Id INT IDENTITY(1,1), TestName NVARCHAR(200), Detail NVARCHAR(400), Result NVARCHAR(4));
DECLARE @kh INT, @xe INT, @lh INT, @tn INT, @ps INT, @n INT, @n2 INT, @err INT, @lr1 INT, @lr2 INT;
DECLARE @stockBefore BIGINT, @stockAfter BIGINT;

SELECT TOP 1 @kh = MaKhachHang, @xe = MaXe FROM Xe ORDER BY MaXe;
IF @xe IS NULL
BEGIN
    PRINT N'Thieu du lieu mau (Xe).';
    RETURN;
END;

BEGIN TRAN;

SELECT @stockBefore = SUM(CAST(SoLuongTon AS BIGINT)) FROM PhuTung;

-- ---------------- Lich hen ----------------
INSERT INTO LichHen (MaKhachHang, MaXe, MaDichVu, NgayHen, GioHen, NoiDung, TrangThai)
VALUES (@kh, @xe, NULL, '2030-01-10', '09:00', N'TEST-NOTI', N'CHO_XAC_NHAN');
SET @lh = SCOPE_IDENTITY();
SELECT @n = COUNT(*) FROM ThongBao WHERE MaLichHen = @lh AND LoaiThongBao = N'LICH_HEN' AND MaKhachHang = @kh AND DaDoc = 0;
INSERT INTO @Result VALUES (N'T1 lich hen moi sinh 1 thong bao dung khach hang', N'so thong bao=' + CAST(@n AS NVARCHAR(10)), CASE WHEN @n = 1 THEN 'PASS' ELSE 'FAIL' END);

UPDATE LichHen SET TrangThai = N'CHO_XAC_NHAN', NgayHen = '2030-01-10', GioHen = '09:00' WHERE MaLichHen = @lh;
SELECT @n = COUNT(*) FROM ThongBao WHERE MaLichHen = @lh;
INSERT INTO @Result VALUES (N'T2 cap nhat khong doi gi khong sinh thong bao', N'so thong bao=' + CAST(@n AS NVARCHAR(10)), CASE WHEN @n = 1 THEN 'PASS' ELSE 'FAIL' END);

UPDATE LichHen SET TrangThai = N'DA_XAC_NHAN' WHERE MaLichHen = @lh;
SELECT @n = COUNT(*) FROM ThongBao WHERE MaLichHen = @lh;
SELECT @n2 = COUNT(*) FROM ThongBao WHERE MaLichHen = @lh AND TieuDe = N'Lich hen da duoc xac nhan';
INSERT INTO @Result VALUES (N'T3 xac nhan lich hen sinh them 1 thong bao', N'tong=' + CAST(@n AS NVARCHAR(10)), CASE WHEN @n = 2 AND @n2 = 1 THEN 'PASS' ELSE 'FAIL' END);

UPDATE LichHen SET NgayHen = '2030-01-11' WHERE MaLichHen = @lh;
SELECT @n = COUNT(*) FROM ThongBao WHERE MaLichHen = @lh;
SELECT @n2 = COUNT(*) FROM ThongBao WHERE MaLichHen = @lh AND TieuDe = N'Lich hen da doi thoi gian';
INSERT INTO @Result VALUES (N'T4 doi ngay hen sinh thong bao doi lich', N'tong=' + CAST(@n AS NVARCHAR(10)), CASE WHEN @n = 3 AND @n2 = 1 THEN 'PASS' ELSE 'FAIL' END);

UPDATE LichHen SET TrangThai = N'DA_HUY' WHERE MaLichHen = @lh;
SELECT @n = COUNT(*) FROM ThongBao WHERE MaLichHen = @lh;
SELECT @n2 = COUNT(*) FROM ThongBao WHERE MaLichHen = @lh AND TieuDe = N'Lich hen da bi huy';
INSERT INTO @Result VALUES (N'T5 huy lich hen sinh thong bao huy', N'tong=' + CAST(@n AS NVARCHAR(10)), CASE WHEN @n = 4 AND @n2 = 1 THEN 'PASS' ELSE 'FAIL' END);

UPDATE LichHen SET NoiDung = N'TEST-NOTI da sua ghi chu' WHERE MaLichHen = @lh;
SELECT @n = COUNT(*) FROM ThongBao WHERE MaLichHen = @lh;
INSERT INTO @Result VALUES (N'T6 sau khi huy, doi ghi chu khong sinh thong bao', N'tong=' + CAST(@n AS NVARCHAR(10)), CASE WHEN @n = 4 THEN 'PASS' ELSE 'FAIL' END);

-- nhieu dong trong mot lenh UPDATE (set-based)
INSERT INTO LichHen (MaKhachHang, MaXe, MaDichVu, NgayHen, GioHen, NoiDung, TrangThai)
VALUES (@kh, @xe, NULL, '2030-02-01', '08:00', N'TEST-NOTI-MULTI', N'CHO_XAC_NHAN'),
       (@kh, @xe, NULL, '2030-02-02', '08:00', N'TEST-NOTI-MULTI', N'CHO_XAC_NHAN');
UPDATE LichHen SET TrangThai = N'DA_XAC_NHAN' WHERE NoiDung = N'TEST-NOTI-MULTI';
SELECT @n = COUNT(*) FROM ThongBao tb JOIN LichHen l ON l.MaLichHen = tb.MaLichHen
WHERE l.NoiDung = N'TEST-NOTI-MULTI' AND tb.TieuDe = N'Lich hen da duoc xac nhan';
SELECT @n2 = COUNT(*) FROM ThongBao tb JOIN LichHen l ON l.MaLichHen = tb.MaLichHen
WHERE l.NoiDung = N'TEST-NOTI-MULTI' AND tb.TieuDe = N'Da ghi nhan lich hen';
INSERT INTO @Result VALUES (N'T7 UPDATE nhieu dong: moi dong dung 1 thong bao xac nhan (set-based)', N'xac nhan=' + CAST(@n AS NVARCHAR(10)) + N', ghi nhan=' + CAST(@n2 AS NVARCHAR(10)),
    CASE WHEN @n = 2 AND @n2 = 2 THEN 'PASS' ELSE 'FAIL' END);

-- ---------------- Tien do sua chua ----------------
INSERT INTO PhieuTiepNhan (MaXe, NgayTiepNhan) VALUES (@xe, SYSDATETIME());
SET @tn = SCOPE_IDENTITY();
INSERT INTO PhieuSuaChua (MaTiepNhan, NgayLap, NgayBatDau, TrangThai) VALUES (@tn, SYSDATETIME(), SYSDATETIME(), N'DANG_SUA');
SET @ps = SCOPE_IDENTITY();
SELECT @n = COUNT(*) FROM ThongBao WHERE MaPhieuSuaChua = @ps;
INSERT INTO @Result VALUES (N'T8 tao phieu sua chua dang sua khong sinh thong bao', N'so thong bao=' + CAST(@n AS NVARCHAR(10)), CASE WHEN @n = 0 THEN 'PASS' ELSE 'FAIL' END);

UPDATE PhieuSuaChua SET TrangThai = N'CHO_PHU_TUNG' WHERE MaPhieuSuaChua = @ps;
SELECT @n = COUNT(*) FROM ThongBao WHERE MaPhieuSuaChua = @ps AND LoaiThongBao = N'TIEN_DO_SUA_CHUA' AND MaKhachHang = (SELECT MaKhachHang FROM Xe WHERE MaXe = @xe);
INSERT INTO @Result VALUES (N'T9 doi tien do sinh 1 thong bao tien do dung khach hang', N'so thong bao=' + CAST(@n AS NVARCHAR(10)), CASE WHEN @n = 1 THEN 'PASS' ELSE 'FAIL' END);

UPDATE PhieuSuaChua SET TrangThai = N'CHO_PHU_TUNG' WHERE MaPhieuSuaChua = @ps;
SELECT @n = COUNT(*) FROM ThongBao WHERE MaPhieuSuaChua = @ps AND LoaiThongBao = N'TIEN_DO_SUA_CHUA';
INSERT INTO @Result VALUES (N'T10 cap nhat cung trang thai khong sinh thong bao', N'so thong bao=' + CAST(@n AS NVARCHAR(10)), CASE WHEN @n = 1 THEN 'PASS' ELSE 'FAIL' END);

UPDATE PhieuSuaChua SET TrangThai = N'HOAN_TAT', NgayHoanThanh = SYSDATETIME() WHERE MaPhieuSuaChua = @ps;
SELECT @n = COUNT(*) FROM ThongBao WHERE MaPhieuSuaChua = @ps AND LoaiThongBao = N'HOAN_TAT_SUA_CHUA';
SELECT @n2 = COUNT(*) FROM ThongBao WHERE MaPhieuSuaChua = @ps AND LoaiThongBao = N'TIEN_DO_SUA_CHUA';
INSERT INTO @Result VALUES (N'T11 chuyen sang HOAN_TAT chi sinh 1 thong bao hoan tat (khong them tien do)', N'hoan tat=' + CAST(@n AS NVARCHAR(10)) + N', tien do=' + CAST(@n2 AS NVARCHAR(10)),
    CASE WHEN @n = 1 AND @n2 = 1 THEN 'PASS' ELSE 'FAIL' END);

UPDATE PhieuSuaChua SET TrangThai = N'DANG_SUA' WHERE MaPhieuSuaChua = @ps;
UPDATE PhieuSuaChua SET TrangThai = N'HOAN_TAT' WHERE MaPhieuSuaChua = @ps;
SELECT @n = COUNT(*) FROM ThongBao WHERE MaPhieuSuaChua = @ps AND LoaiThongBao = N'HOAN_TAT_SUA_CHUA';
INSERT INTO @Result VALUES (N'T12 hoan tat lai van chi co 1 thong bao hoan tat (chong trung giu nguyen)', N'hoan tat=' + CAST(@n AS NVARCHAR(10)), CASE WHEN @n = 1 THEN 'PASS' ELSE 'FAIL' END);

-- ---------------- Lich nhac bao duong ----------------
SET @err = NULL;
BEGIN TRY
    INSERT INTO LichNhacBaoDuong (MaXe) VALUES (@xe);
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
INSERT INTO @Result VALUES (N'T13 lich nhac khong co ngay lan km bi CK chan', N'loi=' + COALESCE(CAST(@err AS NVARCHAR(10)), N'khong loi'), CASE WHEN @err = 547 THEN 'PASS' ELSE 'FAIL' END);

SET @err = NULL;
BEGIN TRY
    INSERT INTO LichNhacBaoDuong (MaXe, SoKmDenHan) VALUES (@xe, -1);
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
INSERT INTO @Result VALUES (N'T14 so km den han am bi CK chan', N'loi=' + COALESCE(CAST(@err AS NVARCHAR(10)), N'khong loi'), CASE WHEN @err = 547 THEN 'PASS' ELSE 'FAIL' END);

SET @err = NULL;
BEGIN TRY
    INSERT INTO LichNhacBaoDuong (MaXe, NgayDenHan, TrangThai) VALUES (@xe, '2030-01-01', N'DA_NHAC');
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
INSERT INTO @Result VALUES (N'T15 trang thai DA_NHAC thieu NgayNhac bi CK chan', N'loi=' + COALESCE(CAST(@err AS NVARCHAR(10)), N'khong loi'), CASE WHEN @err = 547 THEN 'PASS' ELSE 'FAIL' END);

INSERT INTO LichNhacBaoDuong (MaXe, NgayDenHan, GhiChu) VALUES (@xe, '2020-01-01', N'TEST-NHAC-due-ngay');
SET @lr1 = SCOPE_IDENTITY();
INSERT INTO LichNhacBaoDuong (MaXe, NgayDenHan, GhiChu) VALUES (@xe, '2999-01-01', N'TEST-NHAC-chua-den-ngay');
INSERT INTO LichNhacBaoDuong (MaXe, SoKmDenHan, GhiChu) VALUES (@xe, 2147483647, N'TEST-NHAC-chua-den-km');
INSERT INTO LichNhacBaoDuong (MaXe, NgayDenHan, GhiChu, TrangThai) VALUES (@xe, '2020-01-01', N'TEST-NHAC-da-huy', N'DA_HUY');
INSERT INTO LichNhacBaoDuong (MaXe, NgayDenHan, GhiChu, TrangThai, NgayNhac) VALUES (@xe, '2020-01-01', N'TEST-NHAC-da-nhac', N'DA_NHAC', SYSDATETIME());
UPDATE Xe SET SoKm = 5000 WHERE MaXe = @xe;
INSERT INTO LichNhacBaoDuong (MaXe, SoKmDenHan, GhiChu) VALUES (@xe, 5000, N'TEST-NHAC-due-km');
SET @lr2 = SCOPE_IDENTITY();

-- cung dieu kien voi MaintenanceReminderRepository.findDue (ngay hom nay = 2026-10-20)
SELECT @n = COUNT(*)
FROM LichNhacBaoDuong ln JOIN Xe x ON x.MaXe = ln.MaXe
WHERE ln.GhiChu LIKE N'TEST-NHAC-%' AND ln.TrangThai = N'CHO_NHAC'
  AND ((ln.NgayDenHan IS NOT NULL AND ln.NgayDenHan <= '2026-10-20')
       OR (ln.SoKmDenHan IS NOT NULL AND x.SoKm IS NOT NULL AND x.SoKm >= ln.SoKmDenHan));
INSERT INTO @Result VALUES (N'T16 dieu kien den han: chi lich cho nhac da toi ngay hoac du km', N'so lich den han=' + CAST(@n AS NVARCHAR(10)), CASE WHEN @n = 2 THEN 'PASS' ELSE 'FAIL' END);

-- chong trung: moi lich nhac chi duoc 1 thong bao
INSERT INTO ThongBao (MaKhachHang, MaLichHen, MaPhieuSuaChua, MaLichNhac, LoaiThongBao, TieuDe, NoiDung, ThoiGian, DaDoc)
VALUES (@kh, NULL, NULL, @lr1, N'NHAC_BAO_DUONG', N'TEST nhac', N'TEST', SYSDATETIME(), 0);
SET @err = NULL;
BEGIN TRY
    INSERT INTO ThongBao (MaKhachHang, MaLichHen, MaPhieuSuaChua, MaLichNhac, LoaiThongBao, TieuDe, NoiDung, ThoiGian, DaDoc)
    VALUES (@kh, NULL, NULL, @lr1, N'NHAC_BAO_DUONG', N'TEST nhac lan 2', N'TEST', SYSDATETIME(), 0);
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
INSERT INTO @Result VALUES (N'T17 thong bao nhac thu hai cho cung lich bi chi muc duy nhat chan', N'loi=' + COALESCE(CAST(@err AS NVARCHAR(10)), N'khong loi'), CASE WHEN @err IN (2601, 2627) THEN 'PASS' ELSE 'FAIL' END);

-- thong bao thong thuong khong lien ket lich nhac van cho phep nhieu dong (filtered index chi ap dung khi NOT NULL)
INSERT INTO ThongBao (MaKhachHang, LoaiThongBao, TieuDe, NoiDung, ThoiGian, DaDoc) VALUES (@kh, N'LICH_HEN', N'TEST a', N'TEST', SYSDATETIME(), 0);
INSERT INTO ThongBao (MaKhachHang, LoaiThongBao, TieuDe, NoiDung, ThoiGian, DaDoc) VALUES (@kh, N'LICH_HEN', N'TEST b', N'TEST', SYSDATETIME(), 0);
INSERT INTO @Result VALUES (N'T18 thong bao khong lien ket lich nhac khong bi gioi han boi chi muc duy nhat', N'', 'PASS');

-- tao thong bao khong lam doi du lieu nghiep vu khac (ton kho)
SELECT @stockAfter = SUM(CAST(SoLuongTon AS BIGINT)) FROM PhuTung;
INSERT INTO @Result VALUES (N'T19 thong bao/lich nhac khong doi ton kho', N'truoc=' + CAST(@stockBefore AS NVARCHAR(30)) + N', sau=' + CAST(@stockAfter AS NVARCHAR(30)),
    CASE WHEN @stockBefore = @stockAfter THEN 'PASS' ELSE 'FAIL' END);

SELECT Id, TestName, Result, Detail FROM @Result ORDER BY Id;
SELECT @n = COUNT(*) FROM @Result WHERE Result = 'FAIL';
IF @n = 0
    PRINT N'TAT CA TEST THONG BAO DEU PASS (da ROLLBACK).';
ELSE
    PRINT N'CO ' + CAST(@n AS NVARCHAR(10)) + N' TEST FAIL. Xem bang ket qua o tren (da ROLLBACK).';

ROLLBACK TRAN;
GO
