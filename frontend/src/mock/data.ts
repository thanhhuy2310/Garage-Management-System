// Mock data for Gara Ô Tô Thành Công

export const GARAGE_NAME = "Gara Ô Tô Thành Công";
export const DEMO_TODAY = "2024-09-17";

export interface KhachHang {
  MaKhachHang: string;
  HoTen: string;
  SoDienThoai: string;
  Email: string | null;
  DiaChi: string | null;
}

export interface Xe {
  MaXe: string;
  MaKhachHang: string;
  BienSo: string;
  HangXe: string | null;
  DongXe: string | null;
  NamSanXuat: number | null;
  SoKm: number | null;
}

export const khachHang: KhachHang[] = [
  { MaKhachHang: "KH001", HoTen: "Nguyễn Văn An", SoDienThoai: "0901234567", Email: "nguyenvanan@gmail.com", DiaChi: "123 Lê Lợi, Q.1, TP.HCM" },
  { MaKhachHang: "KH002", HoTen: "Trần Thị Bình", SoDienThoai: "0912345678", Email: "tranthib@gmail.com", DiaChi: "45 Nguyễn Huệ, Q.1, TP.HCM" },
  { MaKhachHang: "KH003", HoTen: "Lê Minh Cường", SoDienThoai: "0923456789", Email: "leminhc@yahoo.com", DiaChi: "78 Điện Biên Phủ, Bình Thạnh" },
  { MaKhachHang: "KH004", HoTen: "Phạm Thị Dung", SoDienThoai: "0934567890", Email: "phamthid@gmail.com", DiaChi: "12 Cách Mạng Tháng 8, Q.3" },
  { MaKhachHang: "KH005", HoTen: "Hoàng Văn Em", SoDienThoai: "0945678901", Email: "hoangvane@gmail.com", DiaChi: "56 Hai Bà Trưng, Q.3" },
  { MaKhachHang: "KH006", HoTen: "Vũ Thị Phương", SoDienThoai: "0956789012", Email: "vuthip@gmail.com", DiaChi: "34 Võ Văn Tần, Q.3" },
  { MaKhachHang: "KH007", HoTen: "Đặng Văn Giang", SoDienThoai: "0967890123", Email: "dangvang@gmail.com", DiaChi: "90 Lý Thường Kiệt, Q.10" },
];

export const xe: Xe[] = [
  { MaXe: "XE001", MaKhachHang: "KH001", BienSo: "51G-123.45", HangXe: "Toyota", DongXe: "Camry", NamSanXuat: 2020, SoKm: 45200 },
  { MaXe: "XE002", MaKhachHang: "KH001", BienSo: "51A-456.78", HangXe: "Honda", DongXe: "CR-V", NamSanXuat: 2019, SoKm: 62100 },
  { MaXe: "XE003", MaKhachHang: "KH002", BienSo: "51B-789.01", HangXe: "Kia", DongXe: "Sorento", NamSanXuat: 2021, SoKm: 38500 },
  { MaXe: "XE004", MaKhachHang: "KH003", BienSo: "51C-234.56", HangXe: "Mazda", DongXe: "CX-5", NamSanXuat: 2022, SoKm: 21800 },
  { MaXe: "XE005", MaKhachHang: "KH004", BienSo: "51D-567.89", HangXe: "Ford", DongXe: "EcoSport", NamSanXuat: 2018, SoKm: 89700 },
  { MaXe: "XE006", MaKhachHang: "KH005", BienSo: "51E-890.12", HangXe: "Hyundai", DongXe: "Tucson", NamSanXuat: 2021, SoKm: 33400 },
  { MaXe: "XE007", MaKhachHang: "KH006", BienSo: "51F-345.67", HangXe: "VinFast", DongXe: "VF8", NamSanXuat: 2023, SoKm: 12500 },
  { MaXe: "XE008", MaKhachHang: "KH007", BienSo: "51G-456.78", HangXe: "Mitsubishi", DongXe: "Xpander", NamSanXuat: 2020, SoKm: 48600 },
];

// Compatibility views for screens that have not yet migrated to SQL field names.
export const mockCustomers = khachHang.map((customer) => ({
  id: customer.MaKhachHang,
  name: customer.HoTen,
  phone: customer.SoDienThoai,
  email: customer.Email ?? "",
  address: customer.DiaChi ?? "",
}));

export const mockVehicles = xe.map((vehicle) => ({
  id: vehicle.MaXe,
  ownerId: vehicle.MaKhachHang,
  plate: vehicle.BienSo,
  brand: vehicle.HangXe ?? "",
  model: vehicle.DongXe ?? "",
  year: vehicle.NamSanXuat,
  km: vehicle.SoKm ?? 0,
}));

export interface DichVu {
  MaDichVu: string;
  TenDichVu: string;
  LoaiDichVu: string | null;
  DonGia: number;
  MoTa: string | null;
}

export interface LichHen {
  MaLichHen: string;
  MaKhachHang: string;
  MaXe: string;
  MaDichVu: string | null;
  NgayHen: string;
  GioHen: string;
  NoiDung: string | null;
  TrangThai: AppointmentStatus;
}

export interface PhieuTiepNhan {
  MaTiepNhan: string;
  MaXe: string;
  NgayTiepNhan: string;
  TinhTrangBanDau: string | null;
  YeuCauKhachHang: string | null;
  GhiChu: string | null;
}

export const dichVu: DichVu[] = [
  { MaDichVu: "DV001", TenDichVu: "Bảo dưỡng định kỳ 45.000 km", LoaiDichVu: "Bảo dưỡng", DonGia: 350000, MoTa: "Kiểm tra và bảo dưỡng định kỳ" },
  { MaDichVu: "DV002", TenDichVu: "Sửa chữa phanh", LoaiDichVu: "Sửa chữa", DonGia: 200000, MoTa: "Kiểm tra hệ thống phanh" },
  { MaDichVu: "DV003", TenDichVu: "Điều hòa không mát", LoaiDichVu: "Điện - điều hòa", DonGia: 250000, MoTa: "Kiểm tra hệ thống điều hòa" },
  { MaDichVu: "DV004", TenDichVu: "Kiểm tra động cơ", LoaiDichVu: "Động cơ", DonGia: 180000, MoTa: "Chẩn đoán động cơ" },
  { MaDichVu: "DV005", TenDichVu: "Bảo dưỡng định kỳ", LoaiDichVu: "Bảo dưỡng", DonGia: 250000, MoTa: "Bảo dưỡng tổng quát" },
  { MaDichVu: "DV006", TenDichVu: "Thay lốp xe", LoaiDichVu: "Lốp", DonGia: 120000, MoTa: "Tháo lắp và cân bằng lốp" },
  { MaDichVu: "DV007", TenDichVu: "Sơn xe, chỉnh form", LoaiDichVu: "Đồng sơn", DonGia: 1500000, MoTa: "Sơn và chỉnh form thân vỏ" },
];

export const lichHen: LichHen[] = [
  { MaLichHen: "LH001", MaKhachHang: "KH001", MaXe: "XE001", MaDichVu: "DV001", NgayHen: "2024-09-17", GioHen: "08:00", TrangThai: "confirmed", NoiDung: "Thay dầu, lọc dầu, kiểm tra tổng quát" },
  { MaLichHen: "LH002", MaKhachHang: "KH002", MaXe: "XE003", MaDichVu: "DV002", NgayHen: "2024-09-17", GioHen: "09:30", TrangThai: "arrived", NoiDung: "Tiếng kêu lạ khi đạp phanh" },
  { MaLichHen: "LH003", MaKhachHang: "KH003", MaXe: "XE004", MaDichVu: "DV003", NgayHen: "2024-09-17", GioHen: "14:00", TrangThai: "pending", NoiDung: null },
  { MaLichHen: "LH004", MaKhachHang: "KH004", MaXe: "XE005", MaDichVu: "DV004", NgayHen: "2024-09-18", GioHen: "08:30", TrangThai: "confirmed", NoiDung: "Xe bị rung khi tăng tốc" },
  { MaLichHen: "LH005", MaKhachHang: "KH005", MaXe: "XE006", MaDichVu: "DV005", NgayHen: "2024-09-18", GioHen: "10:00", TrangThai: "pending", NoiDung: null },
  { MaLichHen: "LH006", MaKhachHang: "KH006", MaXe: "XE007", MaDichVu: "DV006", NgayHen: "2024-09-19", GioHen: "08:00", TrangThai: "pending", NoiDung: "Lốp mòn, cần thay 2 lốp trước" },
  { MaLichHen: "LH007", MaKhachHang: "KH007", MaXe: "XE008", MaDichVu: "DV007", NgayHen: "2024-09-20", GioHen: "08:00", TrangThai: "cancelled", NoiDung: "Khách hủy do bận công việc" },
];

export const phieuTiepNhan: PhieuTiepNhan[] = [
  { MaTiepNhan: "TN001", MaXe: "XE001", NgayTiepNhan: "2024-09-17T08:05:00", TinhTrangBanDau: "Ngoại thất xước nhẹ; các hệ thống chính hoạt động bình thường", YeuCauKhachHang: "Bảo dưỡng định kỳ, thay dầu, kiểm tra tổng quát", GhiChu: null },
  { MaTiepNhan: "TN002", MaXe: "XE003", NgayTiepNhan: "2024-09-17T09:35:00", TinhTrangBanDau: "Có tiếng kêu khi đạp phanh", YeuCauKhachHang: "Kiểm tra và sửa chữa hệ thống phanh", GhiChu: null },
  { MaTiepNhan: "TN003", MaXe: "XE005", NgayTiepNhan: "2024-09-14T08:15:00", TinhTrangBanDau: "Xe rung khi tăng tốc", YeuCauKhachHang: "Kiểm tra động cơ", GhiChu: null },
  { MaTiepNhan: "TN004", MaXe: "XE006", NgayTiepNhan: "2024-09-17T10:05:00", TinhTrangBanDau: "Chưa phát hiện bất thường ngoại thất", YeuCauKhachHang: "Bảo dưỡng định kỳ", GhiChu: "Mới tiếp nhận" },
];

export const mockAppointments = lichHen.map((appointment) => {
  const customer = khachHang.find((item) => item.MaKhachHang === appointment.MaKhachHang);
  const vehicle = xe.find((item) => item.MaXe === appointment.MaXe);
  const service = dichVu.find((item) => item.MaDichVu === appointment.MaDichVu);
  return {
    id: appointment.MaLichHen,
    customer: customer?.HoTen ?? "Không xác định",
    customerId: appointment.MaKhachHang,
    vehicle: vehicle?.BienSo ?? "Không xác định",
    vehicleId: appointment.MaXe,
    service: service?.TenDichVu ?? "Chưa chọn dịch vụ",
    serviceId: appointment.MaDichVu,
    date: appointment.NgayHen,
    time: appointment.GioHen,
    status: appointment.TrangThai,
    note: appointment.NoiDung ?? "",
  };
});

export interface PhieuSuaChua {
  MaPhieuSuaChua: string;
  MaTiepNhan: string;
  NgayLap: string;
  NgayBatDau: string | null;
  NgayHoanThanh: string | null;
  TrangThai: RepairStatus;
  KetQua: string | null;
}

export interface PhanCongKyThuatVien {
  MaPhieuSuaChua: string;
  MaKyThuatVien: string;
  NgayPhanCong: string;
  GhiChu: string | null;
}

export const phieuSuaChua: PhieuSuaChua[] = [
  { MaPhieuSuaChua: "PSC001", MaTiepNhan: "TN001", NgayLap: "2024-09-15T08:30:00", NgayBatDau: "2024-09-15T14:00:00", NgayHoanThanh: null, TrangThai: "in_progress", KetQua: null },
  { MaPhieuSuaChua: "PSC002", MaTiepNhan: "TN002", NgayLap: "2024-09-16T10:00:00", NgayBatDau: "2024-09-16T13:30:00", NgayHoanThanh: null, TrangThai: "waiting_parts", KetQua: null },
  { MaPhieuSuaChua: "PSC003", MaTiepNhan: "TN003", NgayLap: "2024-09-14T08:45:00", NgayBatDau: "2024-09-14T09:30:00", NgayHoanThanh: "2024-09-16T15:30:00", TrangThai: "completed", KetQua: "Đã vệ sinh bugi và điều chỉnh bướm ga" },
  { MaPhieuSuaChua: "PSC004", MaTiepNhan: "TN004", NgayLap: "2024-09-17T10:30:00", NgayBatDau: null, NgayHoanThanh: null, TrangThai: "pending", KetQua: null },
];

export const phanCongKyThuatVien: PhanCongKyThuatVien[] = [
  { MaPhieuSuaChua: "PSC001", MaKyThuatVien: "NV002", NgayPhanCong: "2024-09-15T09:00:00", GhiChu: null },
  { MaPhieuSuaChua: "PSC002", MaKyThuatVien: "NV003", NgayPhanCong: "2024-09-16T10:15:00", GhiChu: null },
  { MaPhieuSuaChua: "PSC003", MaKyThuatVien: "NV004", NgayPhanCong: "2024-09-14T09:00:00", GhiChu: null },
  { MaPhieuSuaChua: "PSC004", MaKyThuatVien: "NV002", NgayPhanCong: "2024-09-17T10:45:00", GhiChu: "Chờ kỹ thuật viên kiểm tra xe" },
];

export const mockRepairOrders = [
  {
    id: "PSC001", receptionId: "TN001", vehicle: "51G-123.45", customer: "Nguyễn Văn An", customerId: "KH001", technicianId: "NV002",
    created: "2024-09-15", started: "2024-09-15", technician: "Trần Văn Khoa",
    status: "in_progress", km: 45200,
    items: [
      { type: "service", name: "Thay dầu động cơ", qty: 1, price: 150000, done: true },
      { type: "service", name: "Kiểm tra phanh", qty: 1, price: 80000, done: true },
      { type: "parts", name: "Dầu nhớt Castrol 5W-30 (4L)", qty: 1, price: 320000, done: true },
      { type: "parts", name: "Lọc dầu", qty: 1, price: 95000, done: false },
    ],
    notes: "Khách yêu cầu kiểm tra thêm hệ thống điện"
  },
  {
    id: "PSC002", receptionId: "TN002", vehicle: "51B-789.01", customer: "Trần Thị Bình", customerId: "KH002", technicianId: "NV003",
    created: "2024-09-16", started: "2024-09-16", technician: "Nguyễn Thành Long",
    status: "waiting_parts", km: 38500,
    items: [
      { type: "service", name: "Kiểm tra và sửa phanh trước", qty: 1, price: 200000, done: false },
      { type: "parts", name: "Má phanh trước Kia Sorento", qty: 2, price: 450000, done: false },
    ],
    notes: "Đang chờ má phanh từ kho"
  },
  {
    id: "PSC003", receptionId: "TN003", vehicle: "51D-567.89", customer: "Phạm Thị Dung", customerId: "KH004", technicianId: "NV004",
    created: "2024-09-14", started: "2024-09-14", technician: "Lê Quang Hưng",
    status: "completed", km: 89700,
    items: [
      { type: "service", name: "Kiểm tra và vệ sinh bugi", qty: 1, price: 120000, done: true },
      { type: "service", name: "Điều chỉnh bướm ga", qty: 1, price: 150000, done: true },
      { type: "parts", name: "Bugi NGK (bộ 4)", qty: 1, price: 280000, done: true },
    ],
    notes: ""
  },
  {
    id: "PSC004", receptionId: "TN004", vehicle: "51E-890.12", customer: "Hoàng Văn Em", customerId: "KH005", technicianId: "NV002",
    created: "2024-09-17", started: "2024-09-17", technician: "Trần Văn Khoa",
    status: "pending", km: 33400,
    items: [
      { type: "service", name: "Bảo dưỡng định kỳ 30.000 km", qty: 1, price: 250000, done: false },
    ],
    notes: "Mới tiếp nhận"
  },
];

export const mockQuotations = [
  {
    id: "BG001", repairId: "PSC001", customer: "Nguyễn Văn An", vehicle: "51G-123.45",
    created: "2024-09-15", status: "confirmed",
    services: [
      { name: "Thay dầu động cơ", qty: 1, price: 150000 },
      { name: "Kiểm tra phanh", qty: 1, price: 80000 },
    ],
    parts: [
      { name: "Dầu nhớt Castrol 5W-30 (4L)", qty: 1, price: 320000 },
      { name: "Lọc dầu", qty: 1, price: 95000 },
    ],
  },
  {
    id: "BG002", repairId: "PSC002", customer: "Trần Thị Bình", vehicle: "51B-789.01",
    created: "2024-09-16", status: "pending",
    services: [
      { name: "Kiểm tra và sửa phanh trước", qty: 1, price: 200000 },
    ],
    parts: [
      { name: "Má phanh trước Kia Sorento", qty: 2, price: 450000 },
    ],
  },
  {
    id: "BG003", repairId: "PSC003", customer: "Phạm Thị Dung", vehicle: "51D-567.89",
    created: "2024-09-14", status: "confirmed",
    services: [
      { name: "Kiểm tra và vệ sinh bugi", qty: 1, price: 120000 },
      { name: "Điều chỉnh bướm ga", qty: 1, price: 150000 },
    ],
    parts: [
      { name: "Bugi NGK (bộ 4)", qty: 1, price: 280000 },
    ],
  },
];

export const mockInventory = [
  { id: "PT001", name: "Dầu nhớt Castrol 5W-30 (1L)", brand: "Castrol", unit: "chai", price: 85000, stock: 48, minStock: 20, status: "ok" },
  { id: "PT002", name: "Lọc dầu Toyota", brand: "Toyota", unit: "cái", price: 95000, stock: 12, minStock: 15, status: "low" },
  { id: "PT003", name: "Lọc gió động cơ", brand: "Bosch", unit: "cái", price: 120000, stock: 8, minStock: 10, status: "low" },
  { id: "PT004", name: "Má phanh trước (bộ)", brand: "Brembo", unit: "bộ", price: 450000, stock: 6, minStock: 5, status: "ok" },
  { id: "PT005", name: "Bugi NGK Platinum", brand: "NGK", unit: "cái", price: 75000, stock: 32, minStock: 20, status: "ok" },
  { id: "PT006", name: "Bơm nước (Toyota)", brand: "Toyota", unit: "cái", price: 850000, stock: 2, minStock: 3, status: "low" },
  { id: "PT007", name: "Dây curoa phân phối", brand: "Gates", unit: "bộ", price: 320000, stock: 5, minStock: 5, status: "ok" },
  { id: "PT008", name: "Ắc quy 75Ah", brand: "GS", unit: "cái", price: 1450000, stock: 0, minStock: 2, status: "out" },
  { id: "PT009", name: "Lọc nhiên liệu", brand: "Bosch", unit: "cái", price: 145000, stock: 15, minStock: 10, status: "ok" },
  { id: "PT010", name: "Dầu hộp số tự động (1L)", brand: "Shell", unit: "chai", price: 180000, stock: 24, minStock: 15, status: "ok" },
];

export const mockInvoices = [
  {
    id: "HD001", repairId: "PSC003", customer: "Phạm Thị Dung", customerId: "KH004",
    vehicle: "51D-567.89", created: "2024-09-16",
    services: [
      { name: "Kiểm tra và vệ sinh bugi", qty: 1, price: 120000 },
      { name: "Điều chỉnh bướm ga", qty: 1, price: 150000 },
    ],
    parts: [
      { name: "Bugi NGK (bộ 4)", qty: 1, price: 280000 },
    ],
    status: "paid", paymentMethod: "transfer", paidAt: "2024-09-16",
  },
  {
    id: "HD002", repairId: "PSC001", customer: "Nguyễn Văn An", customerId: "KH001",
    vehicle: "51G-123.45", created: "2024-09-17",
    services: [
      { name: "Thay dầu động cơ", qty: 1, price: 150000 },
      { name: "Kiểm tra phanh", qty: 1, price: 80000 },
    ],
    parts: [
      { name: "Dầu nhớt Castrol 5W-30 (4L)", qty: 1, price: 320000 },
      { name: "Lọc dầu", qty: 1, price: 95000 },
    ],
    status: "unpaid", paymentMethod: null, paidAt: null,
  },
];

export const mockStaff = [
  { id: "NV001", name: "Nguyễn Hữu Bảo", role: "manager", phone: "0901111111", email: "baonguyen@garage.vn", joined: "2019-03-01", status: "active" },
  { id: "NV002", name: "Trần Văn Khoa", role: "technician", phone: "0902222222", email: "khoatran@garage.vn", joined: "2020-06-15", status: "active" },
  { id: "NV003", name: "Nguyễn Thành Long", role: "technician", phone: "0903333333", email: "longnguyen@garage.vn", joined: "2021-01-10", status: "active" },
  { id: "NV004", name: "Lê Quang Hưng", role: "technician", phone: "0904444444", email: "hungle@garage.vn", joined: "2021-08-20", status: "active" },
  { id: "NV005", name: "Phạm Minh Tuấn", role: "receptionist", phone: "0905555555", email: "tuanpham@garage.vn", joined: "2022-02-01", status: "active" },
  { id: "NV006", name: "Vũ Thị Ngọc", role: "receptionist", phone: "0906666666", email: "ngocvu@garage.vn", joined: "2022-09-05", status: "active" },
  { id: "NV007", name: "Đỗ Văn Nam", role: "warehouse", phone: "0907777777", email: "namdo@garage.vn", joined: "2020-11-15", status: "active" },
  { id: "NV008", name: "Lê Thị Hoa", role: "cashier", phone: "0908888888", email: "hoale@garage.vn", joined: "2023-03-01", status: "active" },
];

export const mockNotifications = [
  { id: 1, type: "appointment", title: "Lịch hẹn mới", body: "Nguyễn Văn An đặt lịch bảo dưỡng lúc 08:00 ngày 17/09", time: "08:30 17/09", read: false },
  { id: 2, type: "repair", title: "Sửa chữa hoàn tất", body: "Phiếu PSC003 xe 51D-567.89 đã hoàn tất sửa chữa", time: "15:45 16/09", read: false },
  { id: 3, type: "parts", title: "Phụ tùng sắp hết", body: "Lọc dầu Toyota còn 12 cái (mức tối thiểu: 15)", time: "09:00 16/09", read: true },
  { id: 4, type: "payment", title: "Thanh toán thành công", body: "Hóa đơn HD001 đã được thanh toán 550.000 VNĐ", time: "16:20 16/09", read: true },
  { id: 5, type: "appointment", title: "Khách đến gara", body: "Trần Thị Bình đã đến với lịch hẹn LH002", time: "09:35 17/09", read: false },
  { id: 6, type: "parts", title: "Ắc quy hết hàng", body: "Ắc quy 75Ah đã hết hàng, cần đặt thêm", time: "08:00 17/09", read: false },
];

export const chartRevenue = [
  { date: "11/09", revenue: 3200000, orders: 4 },
  { date: "12/09", revenue: 5800000, orders: 7 },
  { date: "13/09", revenue: 4100000, orders: 5 },
  { date: "14/09", revenue: 6700000, orders: 8 },
  { date: "15/09", revenue: 5200000, orders: 6 },
  { date: "16/09", revenue: 7800000, orders: 9 },
  { date: "17/09", revenue: 3500000, orders: 4 },
];

export const chartMonthly = [
  { month: "T3", revenue: 82000000, orders: 94 },
  { month: "T4", revenue: 95000000, orders: 108 },
  { month: "T5", revenue: 88000000, orders: 101 },
  { month: "T6", revenue: 112000000, orders: 128 },
  { month: "T7", revenue: 103000000, orders: 119 },
  { month: "T8", revenue: 125000000, orders: 143 },
  { month: "T9", revenue: 48000000, orders: 55 },
];

export const chartServices = [
  { name: "Bảo dưỡng", value: 38 },
  { name: "Sửa phanh", value: 18 },
  { name: "Điện - điều hòa", value: 15 },
  { name: "Thay lốp", value: 12 },
  { name: "Động cơ", value: 10 },
  { name: "Khác", value: 7 },
];

export const ROLES: Record<string, string> = {
  customer: "Khách hàng",
  manager: "Quản lý",
  technician: "Kỹ thuật viên",
  receptionist: "NV tiếp nhận",
  warehouse: "NV kho",
  admin: "Quản trị viên",
};

export type AppointmentStatus = "pending" | "confirmed" | "arrived" | "cancelled" | "completed";
export type RepairStatus = "pending" | "in_progress" | "waiting_parts" | "inspecting" | "completed";
export type QuotationStatus = "draft" | "pending" | "confirmed" | "rejected";
export type InvoiceStatus = "paid" | "unpaid";
export type InventoryStatus = "ok" | "low" | "out";

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND" }).format(amount);
}

export function calcTotal(services: { qty: number; price: number }[], parts: { qty: number; price: number }[]): number {
  const s = services.reduce((acc, x) => acc + x.qty * x.price, 0);
  const p = parts.reduce((acc, x) => acc + x.qty * x.price, 0);
  return s + p;
}
