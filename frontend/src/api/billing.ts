import { api, unwrap } from "./client"
import type { ApiResponse } from "./types"
import type {
  BankAccount,
  InvoiceDetail,
  InvoiceSummary,
  PaymentRequest,
} from "../types/billing"

export const billingApi = {
  async invoices(signal?: AbortSignal) {
    return unwrap(
      await api.get<ApiResponse<InvoiceSummary[]>>("/api/invoices", { signal }),
    )
  },
  async invoice(id: number, signal?: AbortSignal) {
    return unwrap(
      await api.get<ApiResponse<InvoiceDetail>>(`/api/invoices/${id}`, {
        signal,
      }),
    )
  },
  async create(repairOrderId: number) {
    return unwrap(
      await api.post<ApiResponse<InvoiceDetail>>("/api/invoices", {
        repairOrderId,
      }),
    )
  },
  async pay(id: number, request: PaymentRequest) {
    return unwrap(
      await api.post<ApiResponse<InvoiceDetail>>(
        `/api/invoices/${id}/payments`,
        request,
        { timeout: 15000 },
      ),
    )
  },
  async banks(signal?: AbortSignal) {
    return unwrap(
      await api.get<ApiResponse<BankAccount[]>>("/api/bank-accounts", {
        signal,
      }),
    )
  },
  async saveBank(request: Omit<BankAccount, "id">, id?: number) {
    return unwrap(
      await api.request<ApiResponse<BankAccount>>({
        url: id ? `/api/bank-accounts/${id}` : "/api/bank-accounts",
        method: id ? "PUT" : "POST",
        data: request,
      }),
    )
  },
}
