# API dịch vụ và phân công kỹ thuật viên

Backend mặc định chạy tại `http://localhost:8080`. Gửi JSON với header
`Content-Type: application/json`.

## Đăng nhập trước khi test

Gọi `POST /api/auth/login` bằng tài khoản trong database:

```json
{
  "username": "<tên đăng nhập>",
  "password": "<mật khẩu>"
}
```

Lấy `data.accessToken` từ response. Trong Postman, chọn **Authorization → Bearer Token**
và dán token. Các API bên dưới đều yêu cầu đăng nhập; thiếu hoặc sai token trả `401`.

## Danh mục dịch vụ

| Method | URL | Quyền |
| --- | --- | --- |
| GET | `/api/services` | Tài khoản đã đăng nhập |
| GET | `/api/services?keyword=Thay%20dau` | Tài khoản đã đăng nhập |
| GET | `/api/services/{id}` | Tài khoản đã đăng nhập |
| POST | `/api/services` | MANAGER, ADMIN |
| PUT | `/api/services/{id}` | MANAGER, ADMIN |

Danh sách nằm trong `data`, sắp theo mã tăng dần. `keyword` tìm trong tên và loại dịch vụ;
bỏ trống thì lấy tất cả. Việc phân biệt dấu tiếng Việt phụ thuộc collation của SQL Server.

Request thêm/cập nhật:

```json
{
  "name": "Thay dầu động cơ",
  "type": "Bảo dưỡng",
  "unitPrice": 250000.00,
  "description": "Thay dầu và kiểm tra mức dầu động cơ."
}
```

Response khi thêm (`201`); đọc và cập nhật trả `200`:

```json
{
  "success": true,
  "message": "Thêm dịch vụ thành công.",
  "data": {
    "id": 12,
    "name": "Thay dầu động cơ",
    "type": "Bảo dưỡng",
    "unitPrice": 250000.00,
    "description": "Thay dầu và kiểm tra mức dầu động cơ."
  }
}
```

Tên bắt buộc, tối đa 150 ký tự; loại tối đa 100; mô tả tối đa 500. Các chuỗi được bỏ
khoảng trắng đầu/cuối; loại và mô tả để trống được lưu `null`. Đơn giá bắt buộc, không âm,
tối đa 16 chữ số nguyên và 2 chữ số thập phân, tương ứng `DECIMAL(18,2)`.

`PUT` thay toàn bộ thông tin dịch vụ, nên cần gửi lại tên và đơn giá. Không gửi loại/mô tả
thì hai trường này được xóa về `null`.

SQL hiện tại không có `TrangThai` và không có ràng buộc tên duy nhất ở `DichVu`.
Vì vậy API cho phép trùng tên, không có endpoint đổi trạng thái hoặc xóa dịch vụ.

Các case cần kiểm tra:

| Thao tác | Kết quả |
| --- | --- |
| Lấy danh sách, tìm theo tên/loại, lấy ID tồn tại | `200` |
| Đọc hoặc cập nhật ID không tồn tại | `404`, `Không tìm thấy dịch vụ.` |
| Thêm hợp lệ rồi đọc lại ID được trả về | `201`, dữ liệu được lưu |
| Cập nhật hợp lệ rồi đọc lại | `200`, dữ liệu mới |
| Tên trống, vượt độ dài, giá âm/thiếu/vượt giới hạn | `400`, `success: false` |
| JSON hoặc kiểu dữ liệu sai | `400` |
| Chưa đăng nhập | `401` |
| CUSTOMER/TECHNICIAN/RECEPTIONIST/WAREHOUSE thêm hoặc sửa | `403` |

## Phân công kỹ thuật viên

Luồng dữ liệu là `PhieuTiepNhan → PhieuSuaChua → PhanCongKyThuatVien → KyThuatVien`.
Các API dưới đây dùng phiếu sửa chữa đã có trong SQL Server. Khách hàng không chọn kỹ thuật viên.

| Method | URL | Quyền |
| --- | --- | --- |
| GET | `/api/technicians` | MANAGER, ADMIN |
| GET | `/api/repair-orders/{repairOrderId}/technicians` | MANAGER, ADMIN |
| POST | `/api/repair-orders/{repairOrderId}/technicians` | MANAGER, ADMIN |
| GET | `/api/technicians/me/repair-orders` | TECHNICIAN |

1. Quản lý gọi `GET /api/technicians` để lấy kỹ thuật viên.
2. Dùng mã phiếu sửa chữa đã có, gọi GET danh sách phân công của phiếu.
3. Gọi POST để thêm kỹ thuật viên. Một phiếu có thể phân công nhiều người.
4. Đăng nhập tài khoản kỹ thuật viên rồi gọi `/api/technicians/me/repair-orders` để xem việc được giao.

Request phân công, ví dụ `POST /api/repair-orders/2/technicians`:

```json
{
  "technicianId": 2,
  "notes": "Kiểm tra hệ thống phanh."
}
```

`technicianId` là `KyThuatVien.MaNhanVien`, không phải mã tài khoản. `notes` không bắt buộc,
tối đa 500 ký tự. Ngày phân công do server ghi nhận theo giờ Việt Nam, chính xác đến giây.

Response (`201`):

```json
{
  "success": true,
  "message": "Phân công kỹ thuật viên thành công.",
  "data": {
    "repairOrderId": 2,
    "technician": { "id": 2, "fullName": "Nguyễn Văn A" },
    "assignedAt": "2026-09-29T09:00:00",
    "notes": "Kiểm tra hệ thống phanh."
  }
}
```

SQL dùng khóa ghép `(MaPhieuSuaChua, MaKyThuatVien)`, không có mã phân công riêng.
GET phân công trả `data` là mảng các bản ghi cùng cấu trúc trên, sắp theo ngày phân công
rồi mã kỹ thuật viên. Phiếu tồn tại nhưng chưa phân công thì trả mảng rỗng.

Response `GET /api/technicians/me/repair-orders` (`200`):

```json
{
  "success": true,
  "message": "Lấy công việc được phân công thành công.",
  "data": [
    {
      "repairOrderId": 2,
      "receptionId": 2,
      "createdAt": "2026-09-29T08:30:00",
      "startedAt": "2026-09-29T09:15:00",
      "completedAt": null,
      "status": "DANG_SUA",
      "result": null,
      "assignedAt": "2026-09-29T09:00:00",
      "notes": "Kiểm tra hệ thống phanh."
    }
  ]
}
```

Danh sách công việc sắp theo ngày phân công giảm dần, bao gồm lịch sử đã hoàn tất.
Trạng thái lấy nguyên giá trị trong `PhieuSuaChua`. API này không nhận mã kỹ thuật viên
từ client: JWT xác định tài khoản, từ đó lấy `TaiKhoan.MaNhanVien` và kiểm tra bản ghi
`KyThuatVien`. Thêm `?technicianId=...` không đổi được người đang xem.

Các case cần kiểm tra:

| Thao tác | Kết quả |
| --- | --- |
| Lấy danh sách kỹ thuật viên | `200`, chỉ những người có trong `KyThuatVien` |
| Xem phiếu chưa phân công | `200`, `data: []` |
| Phân công một hoặc nhiều KTV khác nhau cho cùng phiếu | `201` cho mỗi người |
| Phiếu không tồn tại | `404`, `Không tìm thấy phiếu sửa chữa.` |
| KTV không tồn tại hoặc mã thuộc nhân viên thường | `404`, `Không tìm thấy kỹ thuật viên.` |
| Phân công trùng phiếu + KTV | `409`, giữ nguyên ngày và ghi chú cũ |
| Thiếu/sai mã KTV, mã không dương, ghi chú quá dài | `400` |
| Chưa đăng nhập | `401` |
| CUSTOMER/TECHNICIAN/RECEPTIONIST/WAREHOUSE gọi API phân công hoặc danh sách KTV | `403` |
| KTV A gọi API công việc của mình | Chỉ các phiếu của A; không lộ phiếu riêng của B |
| KTV chưa có công việc | `200`, `data: []` |
| Tài khoản không liên kết đúng bản ghi KTV | `403` |
| Tài khoản bị khóa dùng token cũ | `401` |

Khóa chính hiện có của SQL chặn trùng cả khi hai yêu cầu đến cùng lúc. Backend kiểm tra
trước và xử lý lỗi trùng khóa khi INSERT để trả thông báo nghiệp vụ, không ghi đè phân công cũ.
Các API danh sách dùng DTO với truy vấn join, không tải từng nhân viên riêng lẻ.

## Những phần cần nối tiếp

- Backend chưa có API tiếp nhận xe, tạo/liệt kê phiếu sửa chữa hoặc cập nhật tiến độ thực hiện.
  Luồng đầy đủ bạn cần là **tiếp nhận xe → tạo phiếu → phân công → KTV thực hiện**;
  đợt này bổ sung phần phân công và xem việc, không tự tạo phiếu khi phân công.
- Chưa triển khai gỡ phân công: SQL không có trạng thái phân công và chưa có quy tắc
  xác định lúc nào được gỡ. Các thủ tục xác nhận sử dụng phụ tùng còn kiểm tra bản ghi này,
  nên cần chốt quy tắc giữ lịch sử trước khi thêm API gỡ.
- `NhanVien` và `KyThuatVien` không có trạng thái hoạt động. `TaiKhoan.TrangThai` là trạng thái
  đăng nhập; không coi đó là trạng thái làm việc của nhân viên để tự loại người khỏi danh sách.
- Chưa có quy tắc chặn phân công theo trạng thái phiếu trong code/tài liệu hiện tại.
  API không tự đổi trạng thái phiếu hay thêm điều kiện mới theo trạng thái.
- Không có thay đổi SQL/schema, frontend hoặc mobile trong task này.

## Kiểm thử tự động

Chạy trong thư mục `backend`:

```powershell
.\mvnw.cmd test
.\mvnw.cmd clean package
```

`ServiceControllerTest` và `TechnicianAssignmentControllerTest` gọi API qua MockMvc,
chạy service và repository thật với H2
riêng cho test. Mỗi test rollback dữ liệu. H2 không thay thế việc kiểm tra trực tiếp
SQL Server, nhất là collation và các trigger nghiệp vụ.

Khi `backend/.env` đã kết nối được SQL Server, chạy thêm:

```powershell
.\mvnw.cmd "-Dtest=SqlServerApiIT" test
```

Test này dùng schema đang có, gọi API thêm/sửa/đọc dịch vụ và phân công/xem việc bằng JWT.
Nó tạo dữ liệu tiếp nhận/phiếu/KTV riêng trong transaction và rollback toàn bộ bản ghi sau
khi chạy. SQL Server vẫn có thể tăng bộ đếm IDENTITY dù transaction rollback.
Đây là bộ test riêng cần database local, không nằm trong lệnh test mặc định.

Các test lỗi trùng khi INSERT nằm trong `TechnicianAssignmentServiceTest`.

Database/schema không thay đổi trong hai chức năng này.
