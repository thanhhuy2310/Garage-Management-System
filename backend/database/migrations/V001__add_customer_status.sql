USE QuanLyGaraOTo;
GO

-- Bổ sung trạng thái mà không xóa hoặc tạo lại dữ liệu khách hàng hiện có.
IF COL_LENGTH('dbo.KhachHang', 'TrangThai') IS NULL
BEGIN
    ALTER TABLE dbo.KhachHang
        ADD TrangThai BIT NOT NULL
            CONSTRAINT DF_KhachHang_TrangThai DEFAULT 1 WITH VALUES;
END;
GO
