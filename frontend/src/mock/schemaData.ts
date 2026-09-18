export interface Kho {
  MaKho: string;
  TenKho: string;
  DiaChi: string | null;
}

export interface ChiTietDichVu {
  MaPhieuSuaChua: string;
  MaDichVu: string;
  SoLuong: number;
  DonGia: number;
  TrangThai: string | null;
  ThanhTien: number;
}

export interface ChiTietPhuTung {
  MaPhieuSuaChua: string;
  MaPhuTung: string;
  SoLuong: number;
  DonGia: number;
  ThanhTien: number;
}

export interface PhuTung {
  MaPhuTung: string;
  MaKho: string;
  TenPhuTung: string;
  HangSanXuat: string | null;
  DonGia: number;
  SoLuongTon: number;
  MucTonToiThieu: number;
}

export interface PhieuNhapKho {
  MaPhieuNhap: string;
  NgayNhap: string;
  NhaCungCap: string;
  MaNhanVienKho: string;
  GhiChu: string | null;
}

export interface ChiTietPhieuNhap {
  MaPhieuNhap: string;
  MaPhuTung: string;
  SoLuong: number;
  DonGiaNhap: number;
  ThanhTien: number;
}

export interface PhieuXuatKho {
  MaPhieuXuat: string;
  MaPhieuSuaChua: string | null;
  MaNhanVienKho: string;
  MaKyThuatVienYeuCau: string | null;
  NgayXuat: string;
  LyDo: string;
}

export interface ChiTietPhieuXuat {
  MaPhieuXuat: string;
  MaPhuTung: string;
  SoLuong: number;
  DonGia: number | null;
  DaXacNhanSuDung: boolean;
  NgayXacNhan: string | null;
  MaKyThuatVienXacNhan: string | null;
}

export type LoaiBienDongKho = "NHAP" | "XUAT" | "KIEM_KE";

export interface BienDongKho {
  MaBienDong: string;
  MaPhuTung: string;
  MaPhieuNhap: string | null;
  MaPhieuXuat: string | null;
  ThoiGian: string;
  LoaiBienDong: LoaiBienDongKho;
  SoLuong: number;
  SoLuongTruoc: number | null;
  SoLuongSau: number | null;
  GhiChu: string | null;
}

export interface NhanVien {
  MaNhanVien: string;
  HoTen: string;
  SoDienThoai: string | null;
  Email: string | null;
  ChucVu: string;
}

export interface KyThuatVien {
  MaNhanVien: string;
}

export interface TaiKhoan {
  MaTaiKhoan: string;
  TenDangNhap: string;
  MatKhauHash: string;
  VaiTro: "admin" | "manager" | "technician" | "receptionist" | "warehouse" | "customer";
  TrangThai: boolean;
  MaKhachHang: string | null;
  MaNhanVien: string | null;
}

export interface HoaDon {
  MaHoaDon: string;
  MaPhieuSuaChua: string;
  NgayLap: string;
  TongTien: number;
  TrangThai: "paid" | "unpaid";
}

export interface ThanhToan {
  MaThanhToan: string;
  MaHoaDon: string;
  NgayThanhToan: string;
  SoTien: number;
  PhuongThuc: "cash" | "transfer";
}

export interface ThongBao {
  MaThongBao: string;
  MaKhachHang: string;
  MaLichHen: string | null;
  MaPhieuSuaChua: string | null;
  LoaiThongBao: "appointment" | "repair" | "parts" | "payment";
  TieuDe: string;
  NoiDung: string;
  ThoiGian: string;
  DaDoc: boolean;
}

export const kho: Kho[] = [
  { MaKho: "KHO001", TenKho: "Kho phụ tùng chính", DiaChi: "123 Lê Văn Sỹ, Q.3, TP.HCM" },
];

export const phuTung: PhuTung[] = [
  { MaPhuTung: "PT001", MaKho: "KHO001", TenPhuTung: "Dầu nhớt Castrol 5W-30 (1L)", HangSanXuat: "Castrol", DonGia: 85000, SoLuongTon: 48, MucTonToiThieu: 20 },
  { MaPhuTung: "PT002", MaKho: "KHO001", TenPhuTung: "Lọc dầu Toyota", HangSanXuat: "Toyota", DonGia: 95000, SoLuongTon: 12, MucTonToiThieu: 15 },
  { MaPhuTung: "PT003", MaKho: "KHO001", TenPhuTung: "Lọc gió động cơ", HangSanXuat: "Bosch", DonGia: 120000, SoLuongTon: 8, MucTonToiThieu: 10 },
  { MaPhuTung: "PT004", MaKho: "KHO001", TenPhuTung: "Má phanh trước (bộ)", HangSanXuat: "Brembo", DonGia: 450000, SoLuongTon: 6, MucTonToiThieu: 5 },
  { MaPhuTung: "PT005", MaKho: "KHO001", TenPhuTung: "Bugi NGK Platinum", HangSanXuat: "NGK", DonGia: 75000, SoLuongTon: 32, MucTonToiThieu: 20 },
  { MaPhuTung: "PT006", MaKho: "KHO001", TenPhuTung: "Bơm nước Toyota", HangSanXuat: "Toyota", DonGia: 850000, SoLuongTon: 2, MucTonToiThieu: 3 },
  { MaPhuTung: "PT007", MaKho: "KHO001", TenPhuTung: "Dây curoa phân phối", HangSanXuat: "Gates", DonGia: 320000, SoLuongTon: 5, MucTonToiThieu: 5 },
  { MaPhuTung: "PT008", MaKho: "KHO001", TenPhuTung: "Ắc quy 75Ah", HangSanXuat: "GS", DonGia: 1450000, SoLuongTon: 0, MucTonToiThieu: 2 },
  { MaPhuTung: "PT009", MaKho: "KHO001", TenPhuTung: "Lọc nhiên liệu", HangSanXuat: "Bosch", DonGia: 145000, SoLuongTon: 15, MucTonToiThieu: 10 },
  { MaPhuTung: "PT010", MaKho: "KHO001", TenPhuTung: "Dầu hộp số tự động (1L)", HangSanXuat: "Shell", DonGia: 180000, SoLuongTon: 24, MucTonToiThieu: 15 },
  { MaPhuTung: "PT011", MaKho: "KHO001", TenPhuTung: "Dầu nhớt Castrol 5W-30 (4L)", HangSanXuat: "Castrol", DonGia: 320000, SoLuongTon: 10, MucTonToiThieu: 5 },
];

export const chiTietDichVu: ChiTietDichVu[] = [
  { MaPhieuSuaChua: "PSC001", MaDichVu: "DV008", SoLuong: 1, DonGia: 150000, TrangThai: "completed", ThanhTien: 150000 },
  { MaPhieuSuaChua: "PSC001", MaDichVu: "DV009", SoLuong: 1, DonGia: 80000, TrangThai: "completed", ThanhTien: 80000 },
  { MaPhieuSuaChua: "PSC002", MaDichVu: "DV002", SoLuong: 1, DonGia: 200000, TrangThai: "pending", ThanhTien: 200000 },
  { MaPhieuSuaChua: "PSC003", MaDichVu: "DV010", SoLuong: 1, DonGia: 120000, TrangThai: "completed", ThanhTien: 120000 },
  { MaPhieuSuaChua: "PSC003", MaDichVu: "DV011", SoLuong: 1, DonGia: 150000, TrangThai: "completed", ThanhTien: 150000 },
];

export const chiTietPhuTung: ChiTietPhuTung[] = [
  { MaPhieuSuaChua: "PSC001", MaPhuTung: "PT011", SoLuong: 1, DonGia: 320000, ThanhTien: 320000 },
  { MaPhieuSuaChua: "PSC001", MaPhuTung: "PT002", SoLuong: 1, DonGia: 95000, ThanhTien: 95000 },
  { MaPhieuSuaChua: "PSC002", MaPhuTung: "PT004", SoLuong: 2, DonGia: 450000, ThanhTien: 900000 },
  { MaPhieuSuaChua: "PSC003", MaPhuTung: "PT005", SoLuong: 1, DonGia: 280000, ThanhTien: 280000 },
];

export const phieuNhapKho: PhieuNhapKho[] = [
  { MaPhieuNhap: "PNK001", NgayNhap: "2026-09-15T09:00:00", NhaCungCap: "Công ty Phụ tùng Minh Phúc", MaNhanVienKho: "NV007", GhiChu: "Nhập bổ sung định kỳ" },
  { MaPhieuNhap: "PNK002", NgayNhap: "2026-09-17T08:15:00", NhaCungCap: "Đại lý Toyota chính hãng", MaNhanVienKho: "NV007", GhiChu: null },
];

export const chiTietPhieuNhap: ChiTietPhieuNhap[] = [
  { MaPhieuNhap: "PNK001", MaPhuTung: "PT001", SoLuong: 20, DonGiaNhap: 70000, ThanhTien: 1400000 },
  { MaPhieuNhap: "PNK001", MaPhuTung: "PT002", SoLuong: 10, DonGiaNhap: 78000, ThanhTien: 780000 },
  { MaPhieuNhap: "PNK002", MaPhuTung: "PT004", SoLuong: 4, DonGiaNhap: 380000, ThanhTien: 1520000 },
];

export const phieuXuatKho: PhieuXuatKho[] = [
  { MaPhieuXuat: "PXK001", MaPhieuSuaChua: "PSC001", MaNhanVienKho: "NV007", MaKyThuatVienYeuCau: "NV002", NgayXuat: "2026-09-17T10:00:00", LyDo: "Cấp phụ tùng sửa chữa xe 51G-123.45" },
  { MaPhieuXuat: "PXK002", MaPhieuSuaChua: "PSC002", MaNhanVienKho: "NV007", MaKyThuatVienYeuCau: "NV003", NgayXuat: "2026-09-17T11:20:00", LyDo: "Cấp phụ tùng sửa chữa hệ thống phanh" },
];

export const chiTietPhieuXuat: ChiTietPhieuXuat[] = [
  { MaPhieuXuat: "PXK001", MaPhuTung: "PT011", SoLuong: 1, DonGia: 320000, DaXacNhanSuDung: true, NgayXacNhan: "2026-09-17T10:30:00", MaKyThuatVienXacNhan: "NV002" },
  { MaPhieuXuat: "PXK001", MaPhuTung: "PT002", SoLuong: 1, DonGia: 95000, DaXacNhanSuDung: false, NgayXacNhan: null, MaKyThuatVienXacNhan: null },
  { MaPhieuXuat: "PXK002", MaPhuTung: "PT004", SoLuong: 2, DonGia: 450000, DaXacNhanSuDung: false, NgayXacNhan: null, MaKyThuatVienXacNhan: null },
];

export const bienDongKho: BienDongKho[] = [
  { MaBienDong: "BD001", MaPhuTung: "PT001", MaPhieuNhap: "PNK001", MaPhieuXuat: null, ThoiGian: "2026-09-15T09:00:00", LoaiBienDong: "NHAP", SoLuong: 20, SoLuongTruoc: 28, SoLuongSau: 48, GhiChu: "Nhập kho từ PNK001" },
  { MaBienDong: "BD002", MaPhuTung: "PT011", MaPhieuNhap: null, MaPhieuXuat: "PXK001", ThoiGian: "2026-09-17T10:30:00", LoaiBienDong: "XUAT", SoLuong: 1, SoLuongTruoc: 11, SoLuongSau: 10, GhiChu: "Kỹ thuật viên xác nhận sử dụng" },
  { MaBienDong: "BD003", MaPhuTung: "PT003", MaPhieuNhap: null, MaPhieuXuat: null, ThoiGian: "2026-09-17T16:00:00", LoaiBienDong: "KIEM_KE", SoLuong: -1, SoLuongTruoc: 9, SoLuongSau: 8, GhiChu: "Điều chỉnh sau kiểm kê" },
];

export const nhanVien: NhanVien[] = [
  { MaNhanVien: "NV001", HoTen: "Nguyễn Hữu Bảo", SoDienThoai: "0901111111", Email: "baonguyen@garage.vn", ChucVu: "Quản lý" },
  { MaNhanVien: "NV002", HoTen: "Trần Văn Khoa", SoDienThoai: "0902222222", Email: "khoatran@garage.vn", ChucVu: "Kỹ thuật viên" },
  { MaNhanVien: "NV003", HoTen: "Nguyễn Thành Long", SoDienThoai: "0903333333", Email: "longnguyen@garage.vn", ChucVu: "Kỹ thuật viên" },
  { MaNhanVien: "NV004", HoTen: "Lê Quang Hưng", SoDienThoai: "0904444444", Email: "hungle@garage.vn", ChucVu: "Kỹ thuật viên" },
  { MaNhanVien: "NV005", HoTen: "Phạm Minh Tuấn", SoDienThoai: "0905555555", Email: "tuanpham@garage.vn", ChucVu: "Nhân viên tiếp nhận" },
  { MaNhanVien: "NV006", HoTen: "Vũ Thị Ngọc", SoDienThoai: "0906666666", Email: "ngocvu@garage.vn", ChucVu: "Nhân viên tiếp nhận" },
  { MaNhanVien: "NV007", HoTen: "Đỗ Văn Nam", SoDienThoai: "0907777777", Email: "namdo@garage.vn", ChucVu: "Nhân viên kho" },
  { MaNhanVien: "NV008", HoTen: "Lê Thị Hoa", SoDienThoai: "0908888888", Email: "hoale@garage.vn", ChucVu: "Quản trị viên" },
];

export const kyThuatVien: KyThuatVien[] = [
  { MaNhanVien: "NV002" }, { MaNhanVien: "NV003" }, { MaNhanVien: "NV004" },
];

export const taiKhoan: TaiKhoan[] = [
  { MaTaiKhoan: "TK001", TenDangNhap: "manager", MatKhauHash: "***", VaiTro: "manager", TrangThai: true, MaKhachHang: null, MaNhanVien: "NV001" },
  { MaTaiKhoan: "TK002", TenDangNhap: "technician1", MatKhauHash: "***", VaiTro: "technician", TrangThai: true, MaKhachHang: null, MaNhanVien: "NV002" },
  { MaTaiKhoan: "TK003", TenDangNhap: "technician2", MatKhauHash: "***", VaiTro: "technician", TrangThai: true, MaKhachHang: null, MaNhanVien: "NV003" },
  { MaTaiKhoan: "TK004", TenDangNhap: "technician3", MatKhauHash: "***", VaiTro: "technician", TrangThai: true, MaKhachHang: null, MaNhanVien: "NV004" },
  { MaTaiKhoan: "TK005", TenDangNhap: "reception1", MatKhauHash: "***", VaiTro: "receptionist", TrangThai: true, MaKhachHang: null, MaNhanVien: "NV005" },
  { MaTaiKhoan: "TK006", TenDangNhap: "reception2", MatKhauHash: "***", VaiTro: "receptionist", TrangThai: true, MaKhachHang: null, MaNhanVien: "NV006" },
  { MaTaiKhoan: "TK007", TenDangNhap: "warehouse", MatKhauHash: "***", VaiTro: "warehouse", TrangThai: true, MaKhachHang: null, MaNhanVien: "NV007" },
  { MaTaiKhoan: "TK008", TenDangNhap: "admin", MatKhauHash: "***", VaiTro: "admin", TrangThai: true, MaKhachHang: null, MaNhanVien: "NV008" },
];

export const hoaDon: HoaDon[] = [
  { MaHoaDon: "HD001", MaPhieuSuaChua: "PSC003", NgayLap: "2026-09-16T16:00:00", TongTien: 550000, TrangThai: "paid" },
  { MaHoaDon: "HD002", MaPhieuSuaChua: "PSC001", NgayLap: "2026-09-17T16:30:00", TongTien: 645000, TrangThai: "unpaid" },
];

export const thanhToan: ThanhToan[] = [
  { MaThanhToan: "TT001", MaHoaDon: "HD001", NgayThanhToan: "2026-09-16T16:20:00", SoTien: 550000, PhuongThuc: "transfer" },
];

export const thongBao: ThongBao[] = [
  { MaThongBao: "TB001", MaKhachHang: "KH001", MaLichHen: "LH001", MaPhieuSuaChua: null, LoaiThongBao: "appointment", TieuDe: "Lịch hẹn đã được xác nhận", NoiDung: "Lịch hẹn LH001 lúc 08:00 ngày 17/09/2026 đã được xác nhận.", ThoiGian: "2026-09-16T08:30:00", DaDoc: false },
  { MaThongBao: "TB002", MaKhachHang: "KH004", MaLichHen: null, MaPhieuSuaChua: "PSC003", LoaiThongBao: "repair", TieuDe: "Sửa chữa hoàn tất", NoiDung: "Phiếu PSC003 đã hoàn tất sửa chữa.", ThoiGian: "2026-09-16T15:45:00", DaDoc: false },
  { MaThongBao: "TB003", MaKhachHang: "KH004", MaLichHen: null, MaPhieuSuaChua: "PSC003", LoaiThongBao: "payment", TieuDe: "Thanh toán thành công", NoiDung: "Hóa đơn HD001 đã được thanh toán 550.000 VNĐ.", ThoiGian: "2026-09-16T16:20:00", DaDoc: true },
];

export type InventoryStatus = "ok" | "low" | "out";

export const getInventoryStatus = (item: PhuTung): InventoryStatus =>
  item.SoLuongTon === 0 ? "out" : item.SoLuongTon < item.MucTonToiThieu ? "low" : "ok";

export const mockInventory = phuTung.map((item) => ({
  id: item.MaPhuTung,
  name: item.TenPhuTung,
  brand: item.HangSanXuat ?? "",
  price: item.DonGia,
  stock: item.SoLuongTon,
  minStock: item.MucTonToiThieu,
  status: getInventoryStatus(item),
}));

export const mockStaff = taiKhoan.flatMap((account) => {
  const employee = nhanVien.find((item) => item.MaNhanVien === account.MaNhanVien);
  return employee ? [{ id: employee.MaNhanVien, name: employee.HoTen, role: account.VaiTro, phone: employee.SoDienThoai ?? "", email: employee.Email ?? "", status: account.TrangThai ? "active" : "locked", accountId: account.MaTaiKhoan, username: account.TenDangNhap, title: employee.ChucVu }] : [];
});

export const mockNotifications = thongBao.map((item) => ({
  id: item.MaThongBao,
  customerId: item.MaKhachHang,
  appointmentId: item.MaLichHen,
  repairId: item.MaPhieuSuaChua,
  type: item.LoaiThongBao,
  title: item.TieuDe,
  body: item.NoiDung,
  time: item.ThoiGian,
  read: item.DaDoc,
}));
