import { baoGia, chiTietBaoGia, dichVu, khachHang, lichHen, phanCongKyThuatVien, phieuSuaChua, phieuTiepNhan, xe } from "./data";
import { bienDongKho, chiTietDichVu, chiTietPhieuNhap, chiTietPhieuXuat, chiTietPhuTung, hoaDon, kho, kyThuatVien, nhanVien, phieuNhapKho, phieuXuatKho, phuTung, taiKhoan, thanhToan, thongBao } from "./schemaData";

const ids = <T>(items: T[], getId: (item: T) => string) => new Set(items.map(getId));

export function validateMockRelationships(): string[] {
  const errors: string[] = [];
  const check = (condition: boolean, message: string) => { if (!condition) errors.push(message); };
  const customerIds = ids(khachHang, (x) => x.MaKhachHang);
  const vehicleIds = ids(xe, (x) => x.MaXe);
  const serviceIds = ids(dichVu, (x) => x.MaDichVu);
  const appointmentIds = ids(lichHen, (x) => x.MaLichHen);
  const receptionIds = ids(phieuTiepNhan, (x) => x.MaTiepNhan);
  const repairIds = ids(phieuSuaChua, (x) => x.MaPhieuSuaChua);
  const quoteIds = ids(baoGia, (x) => x.MaBaoGia);
  const employeeIds = ids(nhanVien, (x) => x.MaNhanVien);
  const technicianIds = ids(kyThuatVien, (x) => x.MaNhanVien);
  const warehouseIds = ids(kho, (x) => x.MaKho);
  const partIds = ids(phuTung, (x) => x.MaPhuTung);
  const receiptIds = ids(phieuNhapKho, (x) => x.MaPhieuNhap);
  const issueIds = ids(phieuXuatKho, (x) => x.MaPhieuXuat);
  const invoiceIds = ids(hoaDon, (x) => x.MaHoaDon);

  xe.forEach((x) => check(customerIds.has(x.MaKhachHang), `Xe ${x.MaXe} tham chiếu khách hàng không tồn tại`));
  lichHen.forEach((x) => { check(customerIds.has(x.MaKhachHang), `Lịch ${x.MaLichHen} thiếu khách hàng`); check(vehicleIds.has(x.MaXe) && xe.some((v) => v.MaXe === x.MaXe && v.MaKhachHang === x.MaKhachHang), `Lịch ${x.MaLichHen} dùng xe không thuộc khách hàng`); check(x.MaDichVu === null || serviceIds.has(x.MaDichVu), `Lịch ${x.MaLichHen} thiếu dịch vụ`); });
  phieuTiepNhan.forEach((x) => check(vehicleIds.has(x.MaXe), `Tiếp nhận ${x.MaTiepNhan} thiếu xe`));
  phieuSuaChua.forEach((x) => check(receptionIds.has(x.MaTiepNhan), `Phiếu sửa chữa ${x.MaPhieuSuaChua} thiếu tiếp nhận`));
  phanCongKyThuatVien.forEach((x) => { check(repairIds.has(x.MaPhieuSuaChua), `Phân công thiếu phiếu sửa chữa`); check(technicianIds.has(x.MaKyThuatVien), `Phân công sai kỹ thuật viên ${x.MaKyThuatVien}`); });
  chiTietDichVu.forEach((x) => { check(repairIds.has(x.MaPhieuSuaChua), `Chi tiết dịch vụ thiếu phiếu sửa chữa`); check(serviceIds.has(x.MaDichVu), `Chi tiết dịch vụ thiếu dịch vụ`); check(x.ThanhTien === x.SoLuong * x.DonGia, `Sai thành tiền dịch vụ ${x.MaDichVu}`); });
  chiTietPhuTung.forEach((x) => { check(repairIds.has(x.MaPhieuSuaChua), `Chi tiết phụ tùng thiếu phiếu sửa chữa`); check(partIds.has(x.MaPhuTung), `Chi tiết phụ tùng thiếu phụ tùng`); check(x.ThanhTien === x.SoLuong * x.DonGia, `Sai thành tiền phụ tùng ${x.MaPhuTung}`); });
  baoGia.forEach((x) => { check(repairIds.has(x.MaPhieuSuaChua), `Báo giá ${x.MaBaoGia} thiếu phiếu sửa chữa`); const total = chiTietBaoGia.filter((d) => d.MaBaoGia === x.MaBaoGia).reduce((sum, d) => sum + d.SoLuong * d.DonGia, 0); check(x.TongTien === total, `Tổng tiền báo giá ${x.MaBaoGia} không khớp chi tiết`); });
  chiTietBaoGia.forEach((x) => { check(quoteIds.has(x.MaBaoGia), `Chi tiết báo giá thiếu báo giá`); check((x.MaDichVu !== null) !== (x.MaPhuTung !== null), `Chi tiết báo giá ${x.MaChiTietBaoGia} phải chọn đúng một loại`); check(x.MaDichVu === null || serviceIds.has(x.MaDichVu), `Chi tiết báo giá thiếu dịch vụ`); check(x.MaPhuTung === null || partIds.has(x.MaPhuTung), `Chi tiết báo giá thiếu phụ tùng`); });
  phuTung.forEach((x) => check(warehouseIds.has(x.MaKho), `Phụ tùng ${x.MaPhuTung} thiếu kho`));
  phieuNhapKho.forEach((x) => check(employeeIds.has(x.MaNhanVienKho), `Phiếu nhập ${x.MaPhieuNhap} thiếu nhân viên kho`));
  chiTietPhieuNhap.forEach((x) => { check(receiptIds.has(x.MaPhieuNhap) && partIds.has(x.MaPhuTung), `Chi tiết phiếu nhập sai tham chiếu`); check(x.ThanhTien === x.SoLuong * x.DonGiaNhap, `Sai thành tiền phiếu nhập`); });
  phieuXuatKho.forEach((x) => { check(x.MaPhieuSuaChua === null || repairIds.has(x.MaPhieuSuaChua), `Phiếu xuất ${x.MaPhieuXuat} thiếu phiếu sửa chữa`); check(employeeIds.has(x.MaNhanVienKho), `Phiếu xuất thiếu nhân viên kho`); check(x.MaKyThuatVienYeuCau === null || technicianIds.has(x.MaKyThuatVienYeuCau), `Phiếu xuất sai KTV yêu cầu`); });
  chiTietPhieuXuat.forEach((x) => { check(issueIds.has(x.MaPhieuXuat) && partIds.has(x.MaPhuTung), `Chi tiết phiếu xuất sai tham chiếu`); check(x.DaXacNhanSuDung === (x.NgayXacNhan !== null && x.MaKyThuatVienXacNhan !== null), `Trạng thái xác nhận phiếu xuất không nhất quán`); });
  bienDongKho.forEach((x) => { check(partIds.has(x.MaPhuTung), `Biến động kho thiếu phụ tùng`); check(x.MaPhieuNhap === null || receiptIds.has(x.MaPhieuNhap), `Biến động kho thiếu phiếu nhập`); check(x.MaPhieuXuat === null || issueIds.has(x.MaPhieuXuat), `Biến động kho thiếu phiếu xuất`); check(x.LoaiBienDong === "KIEM_KE" ? x.MaPhieuNhap === null && x.MaPhieuXuat === null : x.LoaiBienDong === "NHAP" ? x.MaPhieuNhap !== null && x.MaPhieuXuat === null : x.MaPhieuNhap === null && x.MaPhieuXuat !== null, `Loại biến động kho không khớp chứng từ`); });
  taiKhoan.forEach((x) => { check((x.MaKhachHang !== null) !== (x.MaNhanVien !== null), `Tài khoản ${x.MaTaiKhoan} phải liên kết đúng một đối tượng`); check(x.MaKhachHang === null || customerIds.has(x.MaKhachHang), `Tài khoản thiếu khách hàng`); check(x.MaNhanVien === null || employeeIds.has(x.MaNhanVien), `Tài khoản thiếu nhân viên`); });
  hoaDon.forEach((x) => check(repairIds.has(x.MaPhieuSuaChua), `Hóa đơn ${x.MaHoaDon} thiếu phiếu sửa chữa`));
  thanhToan.forEach((x) => check(invoiceIds.has(x.MaHoaDon), `Thanh toán ${x.MaThanhToan} thiếu hóa đơn`));
  thongBao.forEach((x) => { check(customerIds.has(x.MaKhachHang), `Thông báo thiếu khách hàng`); check(x.MaLichHen === null || appointmentIds.has(x.MaLichHen), `Thông báo thiếu lịch hẹn`); check(x.MaPhieuSuaChua === null || repairIds.has(x.MaPhieuSuaChua), `Thông báo thiếu phiếu sửa chữa`); });
  return errors;
}
