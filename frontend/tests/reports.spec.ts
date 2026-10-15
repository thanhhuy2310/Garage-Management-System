import { expect, test, type Page } from "@playwright/test"
import type { ReportOverview } from "../src/types/reports"

const report: ReportOverview = {
  from: "2026-01-01",
  to: "2026-10-15",
  billing: {
    invoiced: 15_000_000,
    collected: 12_500_000,
    outstanding: 2_500_000,
    invoiceCount: 8,
    paidInvoiceCount: 6,
  },
  repairs: {
    opened: 14,
    completed: 11,
    inProgress: 3,
    completionRate: 78.57,
    averageHandlingHours: 4.5,
  },
  inventory: {
    imported: 120,
    exported: 75,
    currentStock: 310,
    lowStockParts: 2,
    outOfStockParts: 1,
  },
  vehicleStatuses: [
    { status: "HOAN_TAT", count: 9 },
    { status: "DANG_SUA", count: 3 },
  ],
  trends: [
    { period: "2026-09", invoiced: 7_000_000, collected: 6_000_000, completedRepairs: 5 },
    { period: "2026-10", invoiced: 8_000_000, collected: 6_500_000, completedRepairs: 6 },
  ],
  partMovements: [
    { partId: 1, partName: "Lọc dầu", imported: 50, exported: 30, currentStock: 42 },
  ],
  technicianPerformance: [
    { employeeId: 7, employeeName: "Nguyễn Kỹ Thuật", assigned: 7, completed: 6, completionRate: 85.71, averageHandlingHours: 4.25 },
  ],
}

async function setup(page: Page) {
  const requests: string[] = []
  const account = {
    id: 1,
    username: "manager",
    role: "MANAGER",
    active: true,
    customerId: null,
    employeeId: 1,
  }
  await page.addInitScript((account) => {
    localStorage.setItem("garage_access_token", "test-token")
    localStorage.setItem("garage_account", JSON.stringify(account))
  }, account)
  await page.route((url) => url.pathname.startsWith("/api/"), async (route) => {
    const url = new URL(route.request().url())
    if (url.pathname === "/api/auth/me") {
      return route.fulfill({ json: { success: true, message: "OK", data: account } })
    }
    if (url.pathname === "/api/reports/overview") {
      requests.push(url.search)
      return route.fulfill({ json: { success: true, message: "OK", data: {
        ...report,
        from: url.searchParams.get("from"),
        to: url.searchParams.get("to"),
      } } })
    }
    return route.fulfill({ status: 404, json: { success: false, message: "Unexpected request", data: null } })
  })
  return requests
}

test("manager report renders real API totals and reloads for a selected range", async ({ page }) => {
  const requests = await setup(page)
  await page.goto("/admin/reports")

  await expect(page.getByText("12.500.000 ₫", { exact: true })).toBeVisible()
  await expect(page.getByText("14", { exact: true }).first()).toBeVisible()
  await expect(page.getByText("Nguyễn Kỹ Thuật")).toBeVisible()
  await expect(page.getByText(/MOCK_ONLY/)).toHaveCount(0)

  await page.getByLabel("Từ ngày").fill("2026-09-01")
  await page.getByLabel("Đến ngày").fill("2026-09-30")
  await expect.poll(() => requests.some((query) => query.includes("from=2026-09-01") && query.includes("to=2026-09-30"))).toBe(true)
  await expect(page.getByText("Số liệu từ 01/09/2026 đến 30/09/2026.")).toBeVisible()
})
