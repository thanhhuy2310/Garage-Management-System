SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF COL_LENGTH('dbo.ChiTietPhieuXuat','DaXuatKho') IS NULL
BEGIN
    ALTER TABLE dbo.ChiTietPhieuXuat ADD DaXuatKho bit NOT NULL CONSTRAINT DF_CT_Xuat DEFAULT 0,
        DaNhapTra bit NOT NULL CONSTRAINT DF_CT_Tra DEFAULT 0,
        NgayXuatKho datetime2 NULL, NguoiXuatKho int NULL REFERENCES dbo.NhanVien(MaNhanVien),
        NgayNhapTra datetime2 NULL, NguoiNhapTra int NULL REFERENCES dbo.NhanVien(MaNhanVien);
    -- Old confirmed rows already deducted actual use; their unused parts never left stock.
    -- Preserve both balances and ledger; only mark their historical completion.
    EXEC(N'UPDATE dbo.ChiTietPhieuXuat SET DaXuatKho=1,DaNhapTra=1 WHERE DaXacNhanSuDung=1');
END;
IF EXISTS(SELECT 1 FROM sys.check_constraints WHERE name='CK_BienDongKho_ThamChieu')
    ALTER TABLE dbo.BienDongKho DROP CONSTRAINT CK_BienDongKho_ThamChieu;
ALTER TABLE dbo.BienDongKho ADD CONSTRAINT CK_BienDongKho_ThamChieu CHECK (
    (LoaiBienDong=N'NHAP' AND ((MaPhieuNhap IS NOT NULL AND MaPhieuXuat IS NULL) OR (MaPhieuNhap IS NULL AND MaPhieuXuat IS NOT NULL))) OR
    (LoaiBienDong=N'XUAT' AND MaPhieuNhap IS NULL AND MaPhieuXuat IS NOT NULL) OR
    (LoaiBienDong=N'KIEM_KE' AND MaPhieuNhap IS NULL AND MaPhieuXuat IS NULL));
COMMIT;
GO
-- The legacy procedure deducted stock on use and bypassed current quote/insurance guards.
-- Prevent old clients from running that incompatible write path after this migration.
CREATE OR ALTER PROCEDURE dbo.sp_XacNhanSuDungPhuTung
    @MaPhieuXuat int, @MaPhuTung int, @MaKyThuatVien int, @SoLuongThucDung int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50019,N'Quy trinh kho da thay doi. Xac nhan xuat kho va thuc dung qua API warehouse/exports de bao dam phan quyen va khong tru ton hai lan.',1;
END;
GO
