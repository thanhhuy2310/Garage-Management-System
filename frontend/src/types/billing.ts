export interface InvoiceSummary {
  id: number
  repairOrderId: number
  createdAt: string
  status: string
  total: number
  paid: number
  remaining: number
  licensePlate: string
  customerName: string
}

export interface InvoiceDetail {
  invoice: InvoiceSummary
  lines: {
    type: string
    id: number
    name: string
    quantity: number
    unitPrice: number
  }[]
  payments: {
    id: number
    paidAt: string
    amount: number
    method: string
    bankAccountId: number | null
  }[]
}

export interface BankAccount {
  id: number
  name: string
  bin: string
  account: string
  accountName: string
  active: boolean
}

export interface PaymentRequest {
  amount: number
  method: "TIEN_MAT" | "CHUYEN_KHOAN"
  requestId: string
  bankAccountId: number | null
}
