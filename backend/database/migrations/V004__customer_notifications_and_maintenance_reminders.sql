-- TV3-TUAN10
-- ============================================================
-- V004 - Tuan 10 (TV3): thong bao khach hang va nhac lich bao duong den han
-- Chay SAU V001-V003. Idempotent (chay lai khong loi, khong mat du lieu).
-- Khong tao bang thong bao thu hai: dung lai ThongBao. Khong doi ten bang/cot cu.
--
-- 1. LichNhacBaoDuong: nguon du lieu bao duong DEN HAN do nhan vien khai bao (ngay va/hoac so km).
--    He thong KHONG tu suy ra chu ky bao duong.
-- 2. ThongBao.MaLichNhac + chi muc UNIQUE co dieu kien: moi lich nhac chi sinh dung mot thong bao.
-- 3. TRG_LichHen_ThongBao (moi): thong bao lich hen moi / xac nhan / doi ngay gio / huy (set-based).
-- 4. TRG_PhieuSuaChua_ThongBaoHoanTat (mo rong, KHONG tao trigger thu hai): giu nguyen logic HOAN_TAT va chong trung,
--    them thong bao khi tien do (TrangThai) that su thay doi sang trang thai khac HOAN_TAT.
--
-- Chay bang SSMS hoac "sqlcmd -I" (QUOTED_IDENTIFIER ON): bang ThongBao co chi muc co dieu kien nen moi
-- trigger/INSERT vao ThongBao deu can QUOTED_IDENTIFIER ON.
-- Du lieu mau cua QuanLyGaraOTo.sql duoc nap TRUOC khi trigger nay ton tai nen khong sinh thong bao moi.
-- ============================================================
USE QuanLyGaraOTo;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- ------------------------------------------------------------
-- 1. Lich nhac bao duong den han
-- ------------------------------------------------------------
IF OBJECT_ID(N'dbo.LichNhacBaoDuong', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.LichNhacBaoDuong (
        MaLichNhac     INT IDENTITY(1,1) PRIMARY KEY,
        MaXe           INT NOT NULL,
        MaDichVu       INT NULL,
        NgayDenHan     DATE NULL,
        SoKmDenHan     INT NULL,
        GhiChu         NVARCHAR(500) NULL,
        TrangThai      NVARCHAR(20) NOT NULL CONSTRAINT DF_LichNhacBaoDuong_TrangThai DEFAULT N'CHO_NHAC',
        NgayTao        DATETIME2(0) NOT NULL CONSTRAINT DF_LichNhacBaoDuong_NgayTao DEFAULT SYSDATETIME(),
        MaNhanVienTao  INT NULL,
        NgayNhac       DATETIME2(0) NULL,

        CONSTRAINT FK_LichNhacBaoDuong_Xe FOREIGN KEY (MaXe) REFERENCES dbo.Xe(MaXe),
        CONSTRAINT FK_LichNhacBaoDuong_DichVu FOREIGN KEY (MaDichVu) REFERENCES dbo.DichVu(MaDichVu),
        CONSTRAINT FK_LichNhacBaoDuong_NhanVien FOREIGN KEY (MaNhanVienTao) REFERENCES dbo.NhanVien(MaNhanVien),
        CONSTRAINT CK_LichNhacBaoDuong_TrangThai CHECK (TrangThai IN (N'CHO_NHAC', N'DA_NHAC', N'DA_HUY')),
        -- Phai co ngay den han hoac so km den han (hoac ca hai).
        CONSTRAINT CK_LichNhacBaoDuong_DieuKien CHECK (NgayDenHan IS NOT NULL OR SoKmDenHan IS NOT NULL),
        CONSTRAINT CK_LichNhacBaoDuong_SoKm CHECK (SoKmDenHan IS NULL OR SoKmDenHan >= 0),
        -- Chi lich da nhac moi co thoi diem nhac.
        CONSTRAINT CK_LichNhacBaoDuong_NgayNhac CHECK ((TrangThai = N'DA_NHAC' AND NgayNhac IS NOT NULL)
                                                      OR (TrangThai <> N'DA_NHAC' AND NgayNhac IS NULL))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_LichNhacBaoDuong_ChoNhac' AND object_id = OBJECT_ID(N'dbo.LichNhacBaoDuong'))
    CREATE INDEX IX_LichNhacBaoDuong_ChoNhac
        ON dbo.LichNhacBaoDuong (MaXe) INCLUDE (NgayDenHan, SoKmDenHan)
        WHERE TrangThai = N'CHO_NHAC';
GO

-- ------------------------------------------------------------
-- 2. Lien ket thong bao <-> lich nhac, chong trung bang chi muc duy nhat
-- ------------------------------------------------------------
IF COL_LENGTH('dbo.ThongBao', 'MaLichNhac') IS NULL
    ALTER TABLE dbo.ThongBao ADD MaLichNhac INT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ThongBao_LichNhac')
    ALTER TABLE dbo.ThongBao ADD CONSTRAINT FK_ThongBao_LichNhac
        FOREIGN KEY (MaLichNhac) REFERENCES dbo.LichNhacBaoDuong(MaLichNhac);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_ThongBao_LichNhac' AND object_id = OBJECT_ID(N'dbo.ThongBao'))
    CREATE UNIQUE INDEX UX_ThongBao_LichNhac
        ON dbo.ThongBao (MaLichNhac)
        WHERE MaLichNhac IS NOT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ThongBao_KhachHang_ThoiGian' AND object_id = OBJECT_ID(N'dbo.ThongBao'))
    CREATE INDEX IX_ThongBao_KhachHang_ThoiGian
        ON dbo.ThongBao (MaKhachHang, ThoiGian DESC) INCLUDE (DaDoc);
GO

-- ------------------------------------------------------------
-- 3. Thong bao lich hen (trigger moi tren LichHen, xu ly nhieu dong, so sanh thay doi that su)
--    Moi dong moi lan cap nhat chi sinh toi da MOT thong bao, uu tien: huy > doi ngay/gio > xac nhan.
--    Cap nhat khong doi trang thai/ngay/gio khong sinh thong bao.
-- ------------------------------------------------------------
CREATE OR ALTER TRIGGER dbo.TRG_LichHen_ThongBao
ON dbo.LichHen
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO ThongBao (
        MaKhachHang, MaLichHen, MaPhieuSuaChua, LoaiThongBao, TieuDe, NoiDung, ThoiGian, DaDoc
    )
    SELECT
        i.MaKhachHang,
        i.MaLichHen,
        NULL,
        N'LICH_HEN',
        CASE k.Ma
            WHEN 1 THEN N'Da ghi nhan lich hen'
            WHEN 2 THEN N'Lich hen da duoc xac nhan'
            WHEN 3 THEN N'Lich hen da doi thoi gian'
            ELSE N'Lich hen da bi huy'
        END,
        CASE k.Ma
            WHEN 1 THEN N'Lich hen ngay ' + CONVERT(NVARCHAR(10), i.NgayHen, 103) + N' luc ' + CONVERT(NVARCHAR(5), i.GioHen, 108) + N' da duoc ghi nhan.'
            WHEN 2 THEN N'Lich hen ngay ' + CONVERT(NVARCHAR(10), i.NgayHen, 103) + N' luc ' + CONVERT(NVARCHAR(5), i.GioHen, 108) + N' da duoc gara xac nhan.'
            WHEN 3 THEN N'Lich hen cua ban duoc doi sang ngay ' + CONVERT(NVARCHAR(10), i.NgayHen, 103) + N' luc ' + CONVERT(NVARCHAR(5), i.GioHen, 108) + N'.'
            ELSE N'Lich hen ngay ' + CONVERT(NVARCHAR(10), i.NgayHen, 103) + N' luc ' + CONVERT(NVARCHAR(5), i.GioHen, 108) + N' da bi huy.'
        END,
        SYSDATETIME(),
        0
    FROM inserted i
    LEFT JOIN deleted d ON d.MaLichHen = i.MaLichHen
    CROSS APPLY (
        SELECT CASE
            WHEN d.MaLichHen IS NULL AND i.TrangThai NOT LIKE N'%HUY%' THEN 1
            WHEN d.MaLichHen IS NULL THEN 0
            WHEN i.TrangThai LIKE N'%HUY%' AND ISNULL(d.TrangThai, N'') <> i.TrangThai THEN 4
            WHEN i.TrangThai LIKE N'%HUY%' THEN 0
            WHEN d.NgayHen <> i.NgayHen OR d.GioHen <> i.GioHen THEN 3
            WHEN i.TrangThai = N'DA_XAC_NHAN' AND ISNULL(d.TrangThai, N'') <> i.TrangThai THEN 2
            ELSE 0
        END AS Ma
    ) k
    WHERE k.Ma > 0;
END;
GO

-- ------------------------------------------------------------
-- 4. Tien do sua chua: mo rong TRG_PhieuSuaChua_ThongBaoHoanTat (cung mot trigger, khong them trigger thu hai)
--    Phan HOAN_TAT giu NGUYEN VAN logic va kiem tra chong trung cua ban goc.
-- ------------------------------------------------------------
CREATE OR ALTER TRIGGER dbo.TRG_PhieuSuaChua_ThongBaoHoanTat
ON dbo.PhieuSuaChua
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO ThongBao (
        MaKhachHang,
        MaLichHen,
        MaPhieuSuaChua,
        LoaiThongBao,
        TieuDe,
        NoiDung,
        ThoiGian,
        DaDoc
    )
    SELECT
        x.MaKhachHang,
        NULL,
        i.MaPhieuSuaChua,
        N'HOAN_TAT_SUA_CHUA',
        N'Xe da hoan tat sua chua',
        N'Phieu sua chua #' + CONVERT(NVARCHAR(20), i.MaPhieuSuaChua)
            + N' da hoan tat. Vui long lien he gara de nhan xe.',
        SYSDATETIME(),
        0
    FROM inserted i
    LEFT JOIN deleted d
        ON d.MaPhieuSuaChua = i.MaPhieuSuaChua
    INNER JOIN PhieuTiepNhan ptn
        ON ptn.MaTiepNhan = i.MaTiepNhan
    INNER JOIN Xe x
        ON x.MaXe = ptn.MaXe
    WHERE i.TrangThai = N'HOAN_TAT'
      AND (d.MaPhieuSuaChua IS NULL OR ISNULL(d.TrangThai, N'') <> N'HOAN_TAT')
      AND NOT EXISTS (
          SELECT 1
          FROM ThongBao tb
          WHERE tb.MaPhieuSuaChua = i.MaPhieuSuaChua
            AND tb.LoaiThongBao = N'HOAN_TAT_SUA_CHUA'
      );

    -- Tien do: chi khi UPDATE lam TrangThai that su doi sang trang thai khac HOAN_TAT
    -- (HOAN_TAT da co thong bao rieng o tren nen khong sinh them thong bao tien do).
    INSERT INTO ThongBao (
        MaKhachHang, MaLichHen, MaPhieuSuaChua, LoaiThongBao, TieuDe, NoiDung, ThoiGian, DaDoc
    )
    SELECT
        x.MaKhachHang,
        NULL,
        i.MaPhieuSuaChua,
        N'TIEN_DO_SUA_CHUA',
        N'Cap nhat tien do sua chua',
        N'Phieu sua chua #' + CONVERT(NVARCHAR(20), i.MaPhieuSuaChua) + N' chuyen sang trang thai: '
            + CASE i.TrangThai
                WHEN N'DANG_SUA' THEN N'dang sua chua'
                WHEN N'CHO_PHU_TUNG' THEN N'cho phu tung'
                ELSE i.TrangThai
              END + N'.',
        SYSDATETIME(),
        0
    FROM inserted i
    INNER JOIN deleted d
        ON d.MaPhieuSuaChua = i.MaPhieuSuaChua
    INNER JOIN PhieuTiepNhan ptn
        ON ptn.MaTiepNhan = i.MaTiepNhan
    INNER JOIN Xe x
        ON x.MaXe = ptn.MaXe
    WHERE i.TrangThai <> N'HOAN_TAT'
      AND ISNULL(d.TrangThai, N'') <> i.TrangThai;
END;
GO
