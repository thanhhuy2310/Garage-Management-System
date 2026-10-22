-- Giữ dịch vụ cũ để tra cứu lịch sử, nhưng không cho chọn vào phiếu mới.
IF COL_LENGTH(N'dbo.DichVu', N'TrangThai') IS NULL
BEGIN
    ALTER TABLE dbo.DichVu ADD TrangThai BIT NOT NULL
        CONSTRAINT DF_DichVu_TrangThai DEFAULT 1 WITH VALUES;
END;
GO
