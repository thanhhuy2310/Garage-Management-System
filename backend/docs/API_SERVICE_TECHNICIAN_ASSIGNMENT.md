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

## Kiểm thử tự động

Chạy trong thư mục `backend`:

```powershell
.\mvnw.cmd test
.\mvnw.cmd clean package
```

`ServiceControllerTest` gọi API qua MockMvc, chạy service và repository thật với H2
riêng cho test. Mỗi test rollback dữ liệu. H2 không thay thế việc kiểm tra trực tiếp
SQL Server, nhất là collation và các trigger nghiệp vụ.

Khi `backend/.env` đã kết nối được SQL Server, chạy thêm:

```powershell
.\mvnw.cmd "-Dtest=SqlServerApiIT" test
```

Test này dùng schema đang có, gọi API thêm/sửa/đọc và rollback toàn bộ bản ghi sau
khi chạy. SQL Server vẫn có thể tăng bộ đếm IDENTITY dù transaction rollback.
Đây là bộ test riêng cần database local, không nằm trong lệnh test mặc định.

Database/schema không thay đổi trong phần danh mục dịch vụ.
