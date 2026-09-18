// Mock data for Gara Ô Tô Thành Công

export const GARAGE_NAME = "Gara Ô Tô Thành Công";
export const DEMO_TODAY = "2024-09-17";

export const mockCustomers = [
  { id: "KH001", name: "Nguyễn Văn An", phone: "0901234567", email: "nguyenvanan@gmail.com", address: "123 Lê Lợi, Q.1, TP.HCM", vehicles: 2, joined: "2022-03-15" },
  { id: "KH002", name: "Trần Thị Bình", phone: "0912345678", email: "tranthib@gmail.com", address: "45 Nguyễn Huệ, Q.1, TP.HCM", vehicles: 1, joined: "2021-07-20" },
  { id: "KH003", name: "Lê Minh Cường", phone: "0923456789", email: "leminhc@yahoo.com", address: "78 Điện Biên Phủ, Bình Thạnh", vehicles: 3, joined: "2020-11-05" },
  { id: "KH004", name: "Phạm Thị Dung", phone: "0934567890", email: "phamthid@gmail.com", address: "12 Cách Mạng Tháng 8, Q.3", vehicles: 1, joined: "2023-01-10" },
  { id: "KH005", name: "Hoàng Văn Em", phone: "0945678901", email: "hoangvane@gmail.com", address: "56 Hai Bà Trưng, Q.3", vehicles: 2, joined: "2022-08-22" },
  { id: "KH006", name: "Vũ Thị Phương", phone: "0956789012", email: "vuthip@gmail.com", address: "34 Võ Văn Tần, Q.3", vehicles: 1, joined: "2021-04-14" },
  { id: "KH007", name: "Đặng Văn Giang", phone: "0967890123", email: "dangvang@gmail.com", address: "90 Lý Thường Kiệt, Q.10", vehicles: 2, joined: "2023-05-30" },
];

export const mockVehicles = [
  { id: "XE001", plate: "51G-123.45", owner: "Nguyễn Văn An", ownerId: "KH001", brand: "Toyota", model: "Camry", year: 2020, color: "Đen", vin: "JT2BF22K1W0098765", km: 45200, lastService: "2024-08-15", nextService: "2024-11-15" },
  { id: "XE002", plate: "51A-456.78", owner: "Nguyễn Văn An", ownerId: "KH001", brand: "Honda", model: "CR-V", year: 2019, color: "Trắng", vin: "JHMCR21W1XC005432", km: 62100, lastService: "2024-07-20", nextService: "2024-10-20" },
  { id: "XE003", plate: "51B-789.01", owner: "Trần Thị Bình", ownerId: "KH002", brand: "Kia", model: "Sorento", year: 2021, color: "Xám", vin: "KNDJN2A29B7654321", km: 38500, lastService: "2024-09-01", nextService: "2024-12-01" },
  { id: "XE004", plate: "51C-234.56", owner: "Lê Minh Cường", ownerId: "KH003", brand: "Mazda", model: "CX-5", year: 2022, color: "Đỏ", vin: "JM3KFBDM0N0123456", km: 21800, lastService: "2024-09-10", nextService: "2025-03-10" },
  { id: "XE005", plate: "51D-567.89", owner: "Phạm Thị Dung", ownerId: "KH004", brand: "Ford", model: "EcoSport", year: 2018, color: "Bạc", vin: "MAJ6P1CL2JC987654", km: 89700, lastService: "2024-06-15", nextService: "2024-09-15" },
  { id: "XE006", plate: "51E-890.12", owner: "Hoàng Văn Em", ownerId: "KH005", brand: "Hyundai", model: "Tucson", year: 2021, color: "Xanh", vin: "KM8J3CA46MU456789", km: 33400, lastService: "2024-08-28", nextService: "2024-11-28" },
  { id: "XE007", plate: "51F-345.67", owner: "Vũ Thị Phương", ownerId: "KH006", brand: "VinFast", model: "VF8", year: 2023, color: "Trắng", vin: "VS4XHVB1XP1234567", km: 12500, lastService: "2024-09-05", nextService: "2025-03-05" },
];

export const mockAppointments = [
  { id: "LH001", customer: "Nguyễn Văn An", customerId: "KH001", vehicle: "51G-123.45", service: "Bảo dưỡng định kỳ 45.000 km", date: "2024-09-17", time: "08:00", status: "confirmed", note: "Thay dầu, lọc dầu, kiểm tra tổng quát" },
  { id: "LH002", customer: "Trần Thị Bình", customerId: "KH002", vehicle: "51B-789.01", service: "Sửa chữa phanh", date: "2024-09-17", time: "09:30", status: "arrived", note: "Tiếng kêu lạ khi đạp phanh" },
  { id: "LH003", customer: "Lê Minh Cường", customerId: "KH003", vehicle: "51C-234.56", service: "Điều hòa không mát", date: "2024-09-17", time: "14:00", status: "pending", note: "" },
  { id: "LH004", customer: "Phạm Thị Dung", customerId: "KH004", vehicle: "51D-567.89", service: "Kiểm tra động cơ", date: "2024-09-18", time: "08:30", status: "confirmed", note: "Xe bị rung khi tăng tốc" },
  { id: "LH005", customer: "Hoàng Văn Em", customerId: "KH005", vehicle: "51E-890.12", service: "Bảo dưỡng định kỳ", date: "2024-09-18", time: "10:00", status: "pending", note: "" },
  { id: "LH006", customer: "Vũ Thị Phương", customerId: "KH006", vehicle: "51F-345.67", service: "Thay lốp xe", date: "2024-09-19", time: "08:00", status: "pending", note: "Lốp mòn, cần thay 2 lốp trước" },
  { id: "LH007", customer: "Đặng Văn Giang", customerId: "KH007", vehicle: "51G-456.78", service: "Sơn xe, chỉnh form", date: "2024-09-20", time: "08:00", status: "cancelled", note: "Khách hủy do bận công việc" },
];

export const mockRepairOrders = [
  {
    id: "PSC001", vehicle: "51G-123.45", customer: "Nguyễn Văn An", customerId: "KH001",
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
    id: "PSC002", vehicle: "51B-789.01", customer: "Trần Thị Bình", customerId: "KH002",
    created: "2024-09-16", started: "2024-09-16", technician: "Nguyễn Thành Long",
    status: "waiting_parts", km: 38500,
    items: [
      { type: "service", name: "Kiểm tra và sửa phanh trước", qty: 1, price: 200000, done: false },
      { type: "parts", name: "Má phanh trước Kia Sorento", qty: 2, price: 450000, done: false },
    ],
    notes: "Đang chờ má phanh từ kho"
  },
  {
    id: "PSC003", vehicle: "51D-567.89", customer: "Phạm Thị Dung", customerId: "KH004",
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
    id: "PSC004", vehicle: "51E-890.12", customer: "Hoàng Văn Em", customerId: "KH005",
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
