-- LOCAL DEMO ONLY. Eight related scenarios using the existing schema.
-- Idempotent: existing demo vehicles/orders are never reset. No production data is overwritten.
-- Accounts demo_gara_customer_1..8, demo_gara_manager/warehouse/technician; password demo123.
USE QuanLyGaraOTo;
GO
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET XACT_ABORT ON;
IF COL_LENGTH('ChiTietPhieuXuat','SoLuongThucDung') IS NULL OR OBJECT_ID('NhatKySuaChua','U') IS NULL
    THROW 51100, N'Apply every migration in migrations/README.md first.', 1;
BEGIN TRY
 BEGIN TRAN;
 DECLARE @Lock INT;
 EXEC @Lock=sys.sp_getapplock @Resource=N'garage-integrated-demo-v1',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 51101,N'Demo seed is already running.',1;
 DECLARE @Now DATETIME2(0)=CONVERT(DATETIME2(0),SYSUTCDATETIME() AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time');
 DECLARE @Day DATETIME2(0)=DATEADD(HOUR,8,CONVERT(DATETIME2(0),CONVERT(DATE,@Now)));
 DECLARE @Hash VARCHAR(255)='$2a$10$cmQuil5sXrlLUZ540DVtcuEAIKD4PNfBsj9F0Z2iCby2wUQmaWppK';
 DECLARE @Staff TABLE (Username VARCHAR(100),Name NVARCHAR(100),Role NVARCHAR(50),EmployeeId INT);
 INSERT @Staff VALUES ('demo_gara_manager',N'Nguyễn Thanh Bình',N'MANAGER',NULL),('demo_gara_warehouse',N'Trần Thị Hạnh',N'WAREHOUSE',NULL),('demo_gara_technician',N'Lê Minh Khang',N'TECHNICIAN',NULL);
 INSERT NhanVien(HoTen,Email,ChucVu) SELECT s.Name,s.Username+'@demo.example.test',s.Role FROM @Staff s
 WHERE NOT EXISTS(SELECT 1 FROM NhanVien n WHERE n.Email=s.Username+'@demo.example.test');
 UPDATE s SET EmployeeId=n.MaNhanVien FROM @Staff s JOIN NhanVien n ON n.Email=s.Username+'@demo.example.test';
 IF EXISTS(SELECT 1 FROM @Staff s JOIN TaiKhoan a ON a.TenDangNhap=s.Username WHERE a.VaiTro<>s.Role OR ISNULL(a.MaNhanVien,-1)<>s.EmployeeId)
   THROW 51102,N'Demo staff username belongs to another account.',1;
 INSERT KyThuatVien(MaNhanVien) SELECT EmployeeId FROM @Staff WHERE Role=N'TECHNICIAN' AND NOT EXISTS(SELECT 1 FROM KyThuatVien WHERE MaNhanVien=EmployeeId);
 INSERT TaiKhoan(TenDangNhap,MatKhauHash,VaiTro,TrangThai,MaNhanVien) SELECT Username,@Hash,Role,1,EmployeeId FROM @Staff s WHERE NOT EXISTS(SELECT 1 FROM TaiKhoan WHERE TenDangNhap=s.Username);
 DECLARE @Tech INT=(SELECT EmployeeId FROM @Staff WHERE Role=N'TECHNICIAN'),@Warehouse INT=(SELECT EmployeeId FROM @Staff WHERE Role=N'WAREHOUSE');
 DECLARE @Store INT=(SELECT TOP 1 MaKho FROM Kho ORDER BY MaKho);
 IF @Store IS NULL BEGIN INSERT Kho(TenKho) VALUES(N'Kho phụ tùng'); SET @Store=SCOPE_IDENTITY(); END;
 DECLARE @Service INT=(SELECT TOP 1 MaDichVu FROM DichVu WHERE MoTa=N'DEMO_INTEGRATED_V1_LABOR');
 IF @Service IS NULL BEGIN INSERT DichVu(TenDichVu,LoaiDichVu,DonGia,MoTa,TrangThai) VALUES(N'Công bảo dưỡng thay lọc dầu',N'BAO_DUONG',250000.50,N'DEMO_INTEGRATED_V1_LABOR',1); SET @Service=SCOPE_IDENTITY(); END;
 DECLARE @Part INT=(SELECT TOP 1 MaPhuTung FROM PhuTung WHERE TenPhuTung=N'Lọc dầu động cơ — demo tích hợp' AND HangSanXuat=N'DEMO_INTEGRATED_V1');
 IF @Part IS NULL BEGIN
   INSERT PhuTung(MaKho,TenPhuTung,HangSanXuat,DonGia,SoLuongTon,MucTonToiThieu) VALUES(@Store,N'Lọc dầu động cơ — demo tích hợp',N'DEMO_INTEGRATED_V1',120000.25,0,5); SET @Part=SCOPE_IDENTITY();
   INSERT PhieuNhapKho(NgayNhap,NhaCungCap,MaNhanVienKho,GhiChu) VALUES(DATEADD(DAY,-30,@Day),N'Nhà cung cấp minh họa',@Warehouse,N'DEMO_INTEGRATED_V1');
   DECLARE @Receipt INT=SCOPE_IDENTITY();
   EXEC dbo.sp_ThemChiTietPhieuNhap @Receipt,@Part,20,90000.00;
   UPDATE BienDongKho SET ThoiGian=DATEADD(DAY,-30,@Day) WHERE MaPhieuNhap=@Receipt;
 END;
 DECLARE @Cases TABLE (Id INT PRIMARY KEY,Name NVARCHAR(100),Plate VARCHAR(20),Description NVARCHAR(200),Status NVARCHAR(50),OffsetDays INT);
 INSERT @Cases VALUES
 (1,N'Nguyễn Minh An','51G-880.01',N'Lịch hẹn bảo dưỡng sắp tới',NULL,2),
 (2,N'Trần Ngọc Mai','51G-880.02',N'Đã kiểm tra, chờ khách xác nhận báo giá',N'MOI_TAO',-1),
 (3,N'Lê Hoàng Nam','51G-880.03',N'Khách đã xác nhận, chờ quản lý phân công',N'CHO_SUA',-1),
 (4,N'Phạm Thu Hà','51G-880.04',N'Đang sửa, phụ tùng đã cấp chưa xác nhận thực dùng',N'DANG_SUA',-1),
 (5,N'Võ Quốc Bảo','51G-880.05',N'Tạm dừng chờ phụ tùng',N'CHO_PHU_TUNG',-1),
 (6,N'Đặng Mỹ Linh','51G-880.06',N'Hoàn tất, chưa thanh toán',N'HOAN_TAT',-10),
 (7,N'Bùi Thanh Tùng','51G-880.07',N'Hoàn tất, đã thanh toán đủ',N'HOAN_TAT',-7),
 (8,N'Đỗ Khánh Vy','51G-880.08',N'Hoàn tất, thanh toán một phần',N'HOAN_TAT',-3);
 DECLARE @Id INT=1,@Customer INT,@Vehicle INT,@Reception INT,@Order INT,@Quote INT,@Issue INT,@Invoice INT,@Name NVARCHAR(100),@Plate VARCHAR(20),@Description NVARCHAR(200),@Status NVARCHAR(50),@Offset INT,@At DATETIME2(0),@Username VARCHAR(100),@Phone VARCHAR(20);
 WHILE @Id<=8 BEGIN
  SELECT @Name=Name,@Plate=Plate,@Description=Description,@Status=Status,@Offset=OffsetDays FROM @Cases WHERE Id=@Id;
  SET @Username='demo_gara_customer_'+CONVERT(VARCHAR(2),@Id); SET @Phone='099988000'+CONVERT(VARCHAR(2),@Id); SET @At=DATEADD(DAY,@Offset,@Day);
  SET @Customer=NULL; SET @Vehicle=NULL;
  IF EXISTS(SELECT 1 FROM KhachHang WHERE SoDienThoai=@Phone AND ISNULL(Email,'')<>@Username+'@demo.example.test') THROW 51103,N'Demo phone belongs to another customer.',1;
  SELECT @Customer=MaKhachHang FROM KhachHang WHERE SoDienThoai=@Phone;
  IF @Customer IS NULL BEGIN INSERT KhachHang(HoTen,SoDienThoai,Email,DiaChi,TrangThai) VALUES(@Name,@Phone,@Username+'@demo.example.test',N'TP. Hồ Chí Minh',1); SET @Customer=SCOPE_IDENTITY(); END;
  IF EXISTS(SELECT 1 FROM TaiKhoan WHERE TenDangNhap=@Username AND (ISNULL(MaKhachHang,-1)<>@Customer OR VaiTro<>N'CUSTOMER')) THROW 51104,N'Demo username belongs to another customer.',1;
  IF NOT EXISTS(SELECT 1 FROM TaiKhoan WHERE TenDangNhap=@Username) INSERT TaiKhoan(TenDangNhap,MatKhauHash,VaiTro,TrangThai,MaKhachHang) VALUES(@Username,@Hash,N'CUSTOMER',1,@Customer);
  IF EXISTS(SELECT 1 FROM Xe WHERE BienSo=@Plate AND MaKhachHang<>@Customer) THROW 51105,N'Demo plate belongs to another customer.',1;
  SELECT @Vehicle=MaXe FROM Xe WHERE BienSo=@Plate;
  IF @Vehicle IS NULL BEGIN
   INSERT Xe(MaKhachHang,BienSo,HangXe,DongXe,NamSanXuat,SoKm) VALUES(@Customer,@Plate,N'Toyota',N'Vios',2020,42000+@Id*1000); SET @Vehicle=SCOPE_IDENTITY();
   INSERT LichHen(MaKhachHang,MaXe,MaDichVu,NgayHen,GioHen,NoiDung,TrangThai) VALUES(@Customer,@Vehicle,@Service,CONVERT(DATE,@At),'08:00:00',@Description,CASE WHEN @Id=1 THEN N'DA_XAC_NHAN' ELSE N'DA_DEN' END);
   IF @Id>1 BEGIN
    INSERT PhieuTiepNhan(MaXe,NgayTiepNhan,TinhTrangBanDau,YeuCauKhachHang,GhiChu) VALUES(@Vehicle,@At,N'Đến kỳ bảo dưỡng, cần kiểm tra lọc dầu',N'Bảo dưỡng thay lọc dầu',N'DEMO_INTEGRATED_V1'); SET @Reception=SCOPE_IDENTITY();
    INSERT PhieuSuaChua(MaTiepNhan,NgayLap,NgayBatDau,TrangThai) VALUES(@Reception,DATEADD(MINUTE,15,@At),CASE WHEN @Id>=4 THEN DATEADD(MINUTE,40,@At) ELSE NULL END,CASE WHEN @Id>=6 THEN N'DANG_SUA' ELSE @Status END); SET @Order=SCOPE_IDENTITY();
    INSERT ChiTietDichVu(MaPhieuSuaChua,MaDichVu,SoLuong,DonGia,TrangThai) VALUES(@Order,@Service,1,250000.50,CASE WHEN @Id>=6 THEN N'HOAN_TAT' WHEN @Id>=4 THEN N'DANG_SUA' ELSE N'CHO_SUA' END);
    INSERT ChiTietPhuTung(MaPhieuSuaChua,MaPhuTung,SoLuong,DonGia) VALUES(@Order,@Part,1,120000.25);
    INSERT BaoGia(MaPhieuSuaChua,NgayLap,TongTien,TrangThai,NgayXacNhan) VALUES(@Order,DATEADD(MINUTE,20,@At),370000.75,CASE WHEN @Id=2 THEN N'CHO_XAC_NHAN' ELSE N'DA_XAC_NHAN' END,CASE WHEN @Id=2 THEN NULL ELSE DATEADD(MINUTE,30,@At) END); SET @Quote=SCOPE_IDENTITY();
    INSERT ChiTietBaoGia(MaBaoGia,MaDichVu,MaPhuTung,NoiDung,SoLuong,DonGia) VALUES(@Quote,@Service,NULL,N'Công bảo dưỡng thay lọc dầu',1,250000.50),(@Quote,NULL,@Part,N'Lọc dầu động cơ',1,120000.25);
    INSERT NhatKySuaChua(MaPhieuSuaChua,TrangThai,NoiDung,NguoiCapNhat,ThoiGian) VALUES(@Order,N'MOI_TAO',N'Đã tiếp nhận và kiểm tra xe','demo_gara_manager',DATEADD(MINUTE,15,@At));
    IF @Id>=4 BEGIN
     INSERT PhanCongKyThuatVien(MaPhieuSuaChua,MaKyThuatVien,NgayPhanCong,GhiChu) VALUES(@Order,@Tech,DATEADD(MINUTE,35,@At),N'Thực hiện sau khi khách xác nhận báo giá');
     INSERT NhatKySuaChua(MaPhieuSuaChua,TrangThai,NoiDung,NguoiCapNhat,ThoiGian) VALUES(@Order,N'DANG_SUA',N'Bắt đầu bảo dưỡng','demo_gara_technician',DATEADD(MINUTE,40,@At));
     IF @Id<>5 BEGIN
      INSERT PhieuXuatKho(MaPhieuSuaChua,MaNhanVienKho,MaKyThuatVienYeuCau,NgayXuat,LyDo) VALUES(@Order,@Warehouse,@Tech,DATEADD(MINUTE,50,@At),N'Thay lọc dầu theo báo giá'); SET @Issue=SCOPE_IDENTITY();
      INSERT ChiTietPhieuXuat(MaPhieuXuat,MaPhuTung,SoLuong,DonGia) VALUES(@Issue,@Part,1,120000.25);
      IF @Id>=6 BEGIN
       EXEC dbo.sp_XacNhanSuDungPhuTung @Issue,@Part,@Tech,1;
       UPDATE ChiTietPhieuXuat SET NgayXacNhan=DATEADD(MINUTE,70,@At) WHERE MaPhieuXuat=@Issue;
       UPDATE BienDongKho SET ThoiGian=DATEADD(MINUTE,70,@At) WHERE MaPhieuXuat=@Issue;
      END;
     END;
    END;
    IF @Id>=6 BEGIN
     UPDATE PhieuSuaChua SET TrangThai=N'HOAN_TAT',NgayHoanThanh=DATEADD(MINUTE,90,@At),KetQua=N'Đã thay lọc dầu và kiểm tra vận hành' WHERE MaPhieuSuaChua=@Order;
     INSERT NhatKySuaChua(MaPhieuSuaChua,TrangThai,NoiDung,NguoiCapNhat,ThoiGian) VALUES(@Order,N'HOAN_TAT',N'Đã kiểm tra sau bảo dưỡng','demo_gara_technician',DATEADD(MINUTE,90,@At));
     INSERT HoaDon(MaPhieuSuaChua,NgayLap,TongTien,TrangThai) VALUES(@Order,DATEADD(MINUTE,100,@At),370000.75,CASE WHEN @Id=7 THEN N'DA_THANH_TOAN' ELSE N'CHUA_THANH_TOAN' END); SET @Invoice=SCOPE_IDENTITY();
     IF @Id IN (7,8) INSERT ThanhToan(MaHoaDon,NgayThanhToan,SoTien,PhuongThuc,MaYeuCau) VALUES(@Invoice,DATEADD(MINUTE,110,@At),CASE WHEN @Id=7 THEN 370000.75 ELSE 100000 END,N'TIEN_MAT',CONVERT(VARCHAR(36),NEWID()));
     UPDATE ThongBao SET ThoiGian=DATEADD(MINUTE,90,@At) WHERE MaPhieuSuaChua=@Order;
    END;
   END;
  END;
  SET @Id+=1;
 END;
 COMMIT;
 SELECT c.Id AS Scenario,c.Description,c.Plate,a.TenDangNhap,p.MaPhieuSuaChua,p.TrangThai,h.MaHoaDon,h.TongTien,
   COALESCE(pay.Paid,0) AS Paid,h.TongTien-COALESCE(pay.Paid,0) AS Remaining
 FROM @Cases c JOIN Xe x ON x.BienSo=c.Plate JOIN TaiKhoan a ON a.MaKhachHang=x.MaKhachHang
 LEFT JOIN PhieuTiepNhan r ON r.MaXe=x.MaXe LEFT JOIN PhieuSuaChua p ON p.MaTiepNhan=r.MaTiepNhan
 LEFT JOIN HoaDon h ON h.MaPhieuSuaChua=p.MaPhieuSuaChua
 OUTER APPLY(SELECT SUM(SoTien) Paid FROM ThanhToan WHERE MaHoaDon=h.MaHoaDon) pay ORDER BY c.Id;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
GO
