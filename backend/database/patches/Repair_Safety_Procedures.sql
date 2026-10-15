-- Procedure-only patch. No schema or data reset.
USE QuanLyGaraOTo;
GO
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
