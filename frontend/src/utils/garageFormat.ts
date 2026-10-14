const currencyFormatter = new Intl.NumberFormat("vi-VN", {
  style: "currency",
  currency: "VND",
})
const dateFormatter = new Intl.DateTimeFormat("vi-VN", {
  dateStyle: "short",
  timeStyle: "short",
  timeZone: "Asia/Ho_Chi_Minh",
})

export function formatMoney(value: number) {
  return currencyFormatter.format(value)
}

export function formatGarageDate(value: string | null) {
  if (!value) return "Chưa có"
  // SQL DATETIME2 stores the garage's local time without an offset.
  const date = new Date(
    /(?:Z|[+-]\d{2}:\d{2})$/.test(value) ? value : `${value}+07:00`,
  )
  return Number.isNaN(date.getTime()) ? "—" : dateFormatter.format(date)
}

const STATUS_LABELS: Record<string, string> = {
  MOI_TAO: "Mới tạo",
  DANG_KIEM_TRA: "Đang kiểm tra",
  CHUA_THUC_HIEN: "Chưa thực hiện",
  CHO_SUA: "Chờ sửa chữa",
  CHO_XAC_NHAN: "Chờ xác nhận",
  DANG_SUA: "Đang sửa chữa",
  CHO_PHU_TUNG: "Chờ phụ tùng",
  HOAN_TAT: "Hoàn tất",
  DA_HUY: "Đã hủy",
  HUY: "Đã hủy",
}

export function repairStatusLabel(status: string | null) {
  return status ? (STATUS_LABELS[status] ?? status) : "Chưa cập nhật"
}
