-- ============================================================
-- Test_Vehicles.sql - kiem tra rang buoc bang Xe (Tuan 6 - TV3)
-- Chay trong SSMS sau khi da tao database bang QuanLyGaraOTo.sql.
-- Toan bo du lieu test nam trong mot transaction va duoc ROLLBACK cuoi script.
-- ============================================================
USE QuanLyGaraOTo;
GO

SET NOCOUNT ON;
SET XACT_ABORT OFF;

DECLARE @Result TABLE (
    Id       INT IDENTITY(1,1),
    TestName NVARCHAR(200),
    Expected NVARCHAR(20),
    Detail   NVARCHAR(400),
    Result   NVARCHAR(4)
);

DECLARE @c1 INT, @c2 INT, @n INT;

SELECT TOP 1 @c1 = MaKhachHang FROM KhachHang ORDER BY MaKhachHang;
SELECT TOP 1 @c2 = MaKhachHang FROM KhachHang WHERE MaKhachHang <> @c1 ORDER BY MaKhachHang;

IF @c1 IS NULL
BEGIN
    PRINT N'Khong co khach hang nao trong bang KhachHang. Hay chay QuanLyGaraOTo.sql truoc.';
    RETURN;
END;

BEGIN TRAN;

-- T1: insert xe hop le -> thanh cong
BEGIN TRY
    INSERT INTO Xe (MaKhachHang, BienSo, HangXe, DongXe, NamSanXuat, SoKm)
    VALUES (@c1, 'TEST-VEH-001', N'Toyota', N'Vios', 2021, 1000);
    INSERT INTO @Result VALUES (N'T1 insert xe hop le', 'SUCCESS', N'Insert thanh cong', 'PASS');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T1 insert xe hop le', 'SUCCESS', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T2: trung BienSo -> phai loi UNIQUE (2627/2601)
BEGIN TRY
    INSERT INTO Xe (MaKhachHang, BienSo, HangXe, DongXe, NamSanXuat, SoKm)
    VALUES (@c1, 'TEST-VEH-001', N'Honda', N'City', 2020, 500);
    INSERT INTO @Result VALUES (N'T2 trung BienSo', 'FAIL', N'Insert trung bien so van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T2 trung BienSo', 'FAIL', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() IN (2627, 2601) THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T3: MaKhachHang khong ton tai -> phai loi FK (547)
BEGIN TRY
    INSERT INTO Xe (MaKhachHang, BienSo, HangXe, DongXe, NamSanXuat, SoKm)
    VALUES (-1, 'TEST-VEH-003', N'Kia', N'Seltos', 2023, 100);
    INSERT INTO @Result VALUES (N'T3 khach hang khong ton tai', 'FAIL', N'Insert xe voi khach khong ton tai van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T3 khach hang khong ton tai', 'FAIL', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%FK_Xe_KhachHang%' THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T4: SoKm am -> phai loi CHECK CK_Xe_SoKm (547)
BEGIN TRY
    INSERT INTO Xe (MaKhachHang, BienSo, HangXe, DongXe, NamSanXuat, SoKm)
    VALUES (@c1, 'TEST-VEH-004', N'Mazda', N'Mazda 3', 2022, -1);
    INSERT INTO @Result VALUES (N'T4 SoKm am', 'FAIL', N'Insert SoKm am van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T4 SoKm am', 'FAIL', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%CK_Xe_SoKm%' THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T5: nhieu xe cung mot khach hang, khac bien so -> hop le
BEGIN TRY
    INSERT INTO Xe (MaKhachHang, BienSo, HangXe, DongXe, NamSanXuat, SoKm)
    VALUES (@c1, 'TEST-VEH-005A', N'Toyota', N'Camry', 2019, 20000),
           (@c1, 'TEST-VEH-005B', N'Toyota', N'Fortuner', 2018, 30000);
    SELECT @n = COUNT(*) FROM Xe WHERE MaKhachHang = @c1 AND BienSo LIKE 'TEST-VEH-005%';
    INSERT INTO @Result VALUES (N'T5 nhieu xe cung khach hang', 'SUCCESS', N'So xe test: ' + CAST(@n AS NVARCHAR(10)),
        CASE WHEN @n = 2 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T5 nhieu xe cung khach hang', 'SUCCESS', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T5b: hai khach hang khac nhau van khong duoc dung chung bien so
IF @c2 IS NOT NULL
BEGIN
    BEGIN TRY
        INSERT INTO Xe (MaKhachHang, BienSo, HangXe, DongXe, NamSanXuat, SoKm)
        VALUES (@c2, 'TEST-VEH-005A', N'Honda', N'Civic', 2020, 1000);
        INSERT INTO @Result VALUES (N'T5b trung bien so khac khach hang', 'FAIL', N'Insert van thanh cong', 'FAIL');
    END TRY
    BEGIN CATCH
        INSERT INTO @Result VALUES (N'T5b trung bien so khac khach hang', 'FAIL', ERROR_MESSAGE(),
            CASE WHEN ERROR_NUMBER() IN (2627, 2601) THEN 'PASS' ELSE 'FAIL' END);
    END CATCH;
END;

-- T6: cac gia tri NamSanXuat hop le (NULL, 1886, 1990, nam hien tai, nam sau)
BEGIN TRY
    INSERT INTO Xe (MaKhachHang, BienSo, HangXe, DongXe, NamSanXuat, SoKm)
    VALUES (@c1, 'TEST-VEH-Y0', N'Test', N'Nam NULL', NULL, NULL),
           (@c1, 'TEST-VEH-Y1', N'Test', N'Nam 1886', 1886, 0),
           (@c1, 'TEST-VEH-Y2', N'Test', N'Nam 1990', 1990, 0),
           (@c1, 'TEST-VEH-Y3', N'Test', N'Nam hien tai', YEAR(GETDATE()), 0),
           (@c1, 'TEST-VEH-Y4', N'Test', N'Nam sau', YEAR(GETDATE()) + 1, 0);
    SELECT @n = COUNT(*) FROM Xe WHERE BienSo LIKE 'TEST-VEH-Y_';
    INSERT INTO @Result VALUES (N'T6 NamSanXuat hop le', 'SUCCESS', N'So xe test: ' + CAST(@n AS NVARCHAR(10)),
        CASE WHEN @n = 5 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T6 NamSanXuat hop le', 'SUCCESS', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T6b: NamSanXuat vuot SMALLINT -> phai loi tran so (220/8115)
BEGIN TRY
    INSERT INTO Xe (MaKhachHang, BienSo, HangXe, DongXe, NamSanXuat, SoKm)
    VALUES (@c1, 'TEST-VEH-Y9', N'Test', N'Nam tran so', 40000, 0);
    INSERT INTO @Result VALUES (N'T6b NamSanXuat vuot SMALLINT', 'FAIL', N'Insert van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T6b NamSanXuat vuot SMALLINT', 'FAIL', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() IN (220, 8115) THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

SELECT Id, TestName, Expected, Result, Detail FROM @Result ORDER BY Id;

SELECT @n = COUNT(*) FROM @Result WHERE Result = 'FAIL';
IF @n = 0
    PRINT N'TAT CA TEST VEHICLE DEU PASS.';
ELSE
    PRINT N'CO ' + CAST(@n AS NVARCHAR(10)) + N' TEST FAIL. Xem bang ket qua o tren.';

-- Khong de lai du lieu test trong database.
ROLLBACK TRAN;
GO
