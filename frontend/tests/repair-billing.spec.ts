import { expect, test, type Page } from "@playwright/test"
import type { InvoiceDetail, BankAccount } from "../src/types/billing"

// Fixtures are test-only. Production pages call authenticated backend endpoints.
async function setup(page: Page, role = "MANAGER") {
  const account = {
    id: 1,
    username: "fixture",
    role,
    active: true,
    employeeId: 1,
    customerId: null,
  }
  await page.addInitScript((account) => {
    localStorage.setItem("garage_access_token", "test-token")
    localStorage.setItem("garage_account", JSON.stringify(account))
  }, account)
  const order = {
    id: 42,
    receptionId: 11,
    vehicleId: 7,
    customerId: 8,
    licensePlate: "51A-12345",
    customerName: "Khách kiểm thử",
    status: "HOAN_TAT",
    createdAt: "2026-10-06T08:00:00",
    startedAt: null,
    completedAt: null,
  }
  const invoice: InvoiceDetail = {
    invoice: {
      id: 12,
      repairOrderId: 42,
      createdAt: "2026-10-06T09:00:00",
      status: "CHUA_THANH_TOAN",
      total: 200000,
      paid: 0,
      remaining: 200000,
      licensePlate: order.licensePlate,
      customerName: order.customerName,
    },
    lines: [
      {
        type: "DICH_VU",
        id: 1,
        name: "Kiểm tra phanh",
        quantity: 2,
        unitPrice: 100000,
      },
    ],
    payments: [],
  }
  const state = {
    created: false,
    fail: false,
    losePaymentResponse: false,
    paymentKeys: [] as string[],
    bank: [] as BankAccount[],
  }
  await page.route(
    (url) => url.pathname.startsWith("/api/"),
    async (route) => {
      const req = route.request(),
        path = new URL(req.url()).pathname,
        method = req.method()
      const reply = (data: unknown, status = 200, message = "OK") =>
        route.fulfill({
          status,
          json: { success: status < 400, data, message },
        })
      if (path === "/api/auth/me") return reply(account)
      if (path === "/api/invoices" && method === "GET")
        return state.fail
          ? reply(null, 500, "Không tải được hóa đơn.")
          : reply(state.created ? [invoice.invoice] : [])
      if (path === "/api/repair-orders") return reply([order])
      if (path === "/api/invoices" && method === "POST") {
        expect(req.postDataJSON()).toEqual({ repairOrderId: 42 })
        state.created = true
        return reply(invoice, 201)
      }
      if (path === "/api/invoices/12") return reply(invoice)
      if (path === "/api/bank-accounts" && method === "GET")
        return reply(state.bank)
      if (path === "/api/bank-accounts" && method === "POST") {
        const bank = { ...req.postDataJSON(), id: state.bank.length + 1 }
        state.bank.push(bank)
        return reply(bank, 201)
      }
      if (path === "/api/invoices/12/payments") {
        const request = req.postDataJSON()
        if (!state.paymentKeys.includes(request.requestId)) {
          if (request.amount > invoice.invoice.remaining)
            return reply(null, 409, "Số tiền vượt quá số còn phải thanh toán.")
          invoice.invoice.paid += request.amount
          invoice.invoice.remaining -= request.amount
          invoice.payments.push({
            ...request,
            id: invoice.payments.length + 1,
            paidAt: "2026-10-06T10:00:00",
          })
        }
        state.paymentKeys.push(request.requestId)
        if (state.losePaymentResponse) {
          state.losePaymentResponse = false
          return route.abort("failed")
        }
        return reply(invoice)
      }
      return reply(null, 404, "Unexpected fixture request")
    },
  )
  return state
}

async function noOverflow(page: Page) {
  expect(
    await page
      .locator("#admin-content")
      .evaluate((e) => e.scrollWidth <= e.clientWidth),
  ).toBe(true)
}

test("create invoice, collect in installments and reload real-shaped data", async ({
  page,
}) => {
  await setup(page)
  await page.goto("/admin/invoice")
  await expect(page.getByText(/Chưa có hóa đơn/)).toBeVisible()
  await page.getByRole("button", { name: "Lập hóa đơn", exact: true }).click()
  await page.getByLabel("Phiếu sửa chữa đã hoàn tất").selectOption("42")
  await page
    .getByRole("dialog")
    .getByRole("button", { name: "Lập hóa đơn", exact: true })
    .click()
  await expect(
    page.getByRole("heading", { name: "Hóa đơn #12", exact: true }),
  ).toBeVisible()
  await page.getByRole("button", { name: "Ghi nhận thanh toán" }).click()
  await page.getByLabel("Số tiền đã nhận (đ)").fill("50000")
  await page.getByRole("checkbox").check()
  await page.getByRole("button", { name: "Xác nhận đã nhận tiền" }).click()
  await expect(page.getByRole("dialog")).toHaveCount(0)
  await page.reload()
  await expect(page.getByText("150.000 ₫", { exact: true })).toBeVisible()
  await expect(page.getByText("Tiền mặt", { exact: true })).toBeVisible()
  await noOverflow(page)
  await page.screenshot({
    path: test.info().outputPath("invoice.png"),
    fullPage: true,
  })
})

test("lost payment response retries the same request without charging twice", async ({
  page,
}) => {
  await page.addInitScript(() => Object.defineProperty(crypto, "randomUUID", { value: undefined }))
  const state = await setup(page)
  state.created = true
  state.losePaymentResponse = true
  await page.goto("/admin/invoice")
  await page.getByRole("button", { name: "Ghi nhận thanh toán" }).click()
  await page.getByLabel("Số tiền đã nhận (đ)").fill("50000")
  await page.getByRole("checkbox").check()
  await page.getByRole("button", { name: "Xác nhận đã nhận tiền" }).click()
  await expect(page.getByRole("alert")).toBeVisible()
  await page.getByRole("button", { name: "Đóng hộp thoại" }).click()
  await page.getByRole("button", { name: "Ghi nhận thanh toán" }).click()
  await expect(page.getByLabel("Số tiền đã nhận (đ)")).toBeDisabled()
  await page.getByRole("checkbox").check()
  await page.getByRole("button", { name: "Xác nhận đã nhận tiền" }).click()
  await expect(page.getByRole("dialog")).toHaveCount(0)
  expect(state.paymentKeys).toHaveLength(2)
  expect(state.paymentKeys[0]).toBe(state.paymentKeys[1])
  expect(state.paymentKeys[0]).toMatch(/^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$/)
  await expect(page.getByText("150.000 ₫", { exact: true })).toBeVisible()
})

test("multiple banks persist and QR expires without pretending money was received", async ({
  page,
}) => {
  const state = await setup(page)
  state.created = true
  await page.goto("/admin/invoice")
  await page
    .getByRole("button", { name: "Tài khoản ngân hàng", exact: true })
    .click()
  await page.getByLabel("Ngân hàng", { exact: true }).selectOption("970422")
  await page
    .getByLabel("Số tài khoản", { exact: true })
    .pressSequentially("1234567890")
  await page.getByRole("button", { name: "Lưu tài khoản" }).click()
  await expect(page.getByRole("status")).toHaveText(
    "Đã lưu tài khoản ngân hàng.",
  )
  await page.getByLabel("Ngân hàng", { exact: true }).selectOption("970436")
  await page.getByLabel("Số tài khoản", { exact: true }).fill("2234567890")
  await page.getByRole("button", { name: "Lưu tài khoản" }).click()
  await expect(
    page.getByRole("button", { name: /Vietcombank · Đang sử dụng/ }),
  ).toBeVisible()
  await page.getByRole("button", { name: "Đóng hộp thoại" }).click()
  await page.reload()
  await page.getByRole("button", { name: "Ghi nhận thanh toán" }).click()
  await page.getByLabel("Phương thức").selectOption("CHUYEN_KHOAN")
  await page.getByLabel("Tài khoản nhận tiền").selectOption("2")
  await expect(page.getByText("Vietcombank", { exact: true })).toBeVisible()
  await expect(page.getByText("2234567890", { exact: true })).toBeVisible()
  await expect(page.locator("svg title")).toHaveText(
    "QR chuyển khoản hóa đơn 12",
  )
  await page.clock.install()
  await page.clock.fastForward(901000)
  await expect(page.getByRole("button", { name: "Tạo QR mới" })).toBeVisible()
  expect(state.paymentKeys).toHaveLength(0)
  await page.getByRole("button", { name: "Tạo QR mới" }).click()
  await expect(page.getByRole("button", { name: "Tạo QR mới" })).toHaveCount(0)
})

test("invoice failure retries, and receptionist cannot configure receiving accounts", async ({
  page,
}) => {
  const state = await setup(page, "RECEPTIONIST")
  state.fail = true
  await page.goto("/admin/invoice")
  await expect(page.getByRole("alert")).toHaveText("Không tải được hóa đơn.")
  await expect(
    page.getByRole("button", { name: "Tài khoản ngân hàng" }),
  ).toHaveCount(0)
  state.fail = false
  await page.getByRole("button", { name: "Thử lại" }).click()
  await expect(page.getByText(/Chưa có hóa đơn/)).toBeVisible()
})

test("technician updates a service and completed repair, then returns to the list", async ({
  page,
}) => {
  await setup(page, "TECHNICIAN")
  const detail = {
    order: {
      id: 42,
      receptionId: 11,
      licensePlate: "51A-12345",
      customerName: "Khách kiểm thử",
      status: "DANG_SUA",
      createdAt: "2026-10-06T08:00:00",
      startedAt: "2026-10-06T09:00:00",
      completedAt: null as string | null,
    },
    services: [
      {
        id: 1,
        name: "Kiểm tra phanh",
        quantity: 1,
        unitPrice: 200000,
        status: "DANG_SUA",
      },
    ],
    assignments: [
      {
        technician: { id: 1, fullName: "Kỹ thuật viên A" },
        assignedAt: "2026-10-06T08:00:00",
      },
    ],
    progress: [] as object[],
  }
  await page.route("**/api/repair-orders**", async (route) => {
    const path = new URL(route.request().url()).pathname
    if (route.request().method() === "PUT") {
      const update = route.request().postDataJSON()
      if (path.includes("/services/")) {
        expect(update.expectedStatus).toBe("DANG_SUA")
        detail.services[0].status = update.status
      } else {
        detail.order.status = update.status
        detail.order.completedAt = "2026-10-06T10:00:00"
      }
      detail.progress.unshift({
        id: detail.progress.length + 1,
        ...update,
        updatedBy: "KTV",
        createdAt: "2026-10-06T10:00:00",
      })
    }
    return route.fulfill({
      json: {
        success: true,
        data: path === "/api/repair-orders" ? [detail.order] : detail,
      },
    })
  })
  await page.goto("/admin/technician")
  await page.getByRole("button", { name: /Xem phiếu #42/ }).click()
  await page
    .getByRole("button", { name: "Cập nhật Kiểm tra phanh", exact: true })
    .click()
  await page
    .getByLabel("Nội dung cập nhật")
    .pressSequentially("Da kiem tra phanh")
  await page.getByRole("button", { name: "Lưu tiến độ" }).click()
  await expect(page.getByRole("dialog")).toHaveCount(0)
  await page
    .getByRole("button", { name: "Cập nhật tiến độ", exact: true })
    .click()
  await page.getByLabel("Chuyển trạng thái").selectOption("HOAN_TAT")
  await page.getByLabel("Kết quả sửa chữa").fill("Đã sửa xong và kiểm tra xe.")
  await page.getByRole("button", { name: "Lưu tiến độ" }).click()
  await expect(page.getByRole("dialog")).toHaveCount(0)
  await expect(page.getByText("Đã sửa xong và kiểm tra xe.")).toBeVisible()
  await expect(
    page.getByRole("button", { name: "Cập nhật tiến độ", exact: true }),
  ).toHaveCount(0)
  await noOverflow(page)
  await page.getByRole("button", { name: "Quay lại danh sách" }).click()
  await expect(
    page.getByRole("button", { name: /Xem phiếu #42/ }),
  ).toBeVisible()
})
