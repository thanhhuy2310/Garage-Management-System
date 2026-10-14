import { expect, test, type Page } from "@playwright/test"

const order = {
  id: 42,
  receptionId: 18,
  licensePlate: "51A-12345",
  brand: "Toyota",
  model: "Vios",
  customerName: "Khách kiểm thử",
  createdAt: "2026-10-01T08:00:00",
  startedAt: null,
  completedAt: null,
  status: "DANG_SUA",
  result: null,
  customerRequest: "Kiểm tra phanh",
  initialCondition: "Phanh kêu",
}
const service = {
  id: 11,
  name: "Bảo dưỡng định kỳ",
  type: "Bảo dưỡng",
  unitPrice: 250000,
  description: "Kiểm tra xe",
}

// API fixtures are isolated to browser tests. Application pages always call the backend.
async function setup(page: Page, role = "MANAGER") {
  const account = {
    id: 1,
    username: "test-user",
    role,
    active: true,
    customerId: null,
    employeeId: 7,
  }
  await page.addInitScript((account) => {
    localStorage.setItem("garage_access_token", "test-token")
    localStorage.setItem("garage_account", JSON.stringify(account))
  }, account)
  let services = [service]
  const assignments: object[] = []
  let failList = false
  let conflict = false
  await page.route(
    (url) => url.pathname.startsWith("/api/"),
    async (route) => {
      const request = route.request()
      const path = new URL(request.url()).pathname
      const method = request.method()
      const reply = (data: unknown, status = 200, message = "OK") =>
        route.fulfill({
          status,
          json: { success: status < 400, message, data },
        })
      if (path === "/api/auth/me") return reply(account)
      if (path === "/api/services" && method === "GET")
        return failList
          ? reply(null, 500, "Không tải được dịch vụ.")
          : reply(services)
      if (path === "/api/services" && method === "POST") {
        const created = { ...request.postDataJSON(), id: 12 }
        services.push(created)
        return reply(created, 201)
      }
      if (path === "/api/services/11" && method === "PUT") {
        const updated = { ...request.postDataJSON(), id: 11 }
        services = services.map((item) => (item.id === 11 ? updated : item))
        return reply(updated)
      }
      if (path === "/api/repair-orders") return reply([order])
      if (path === "/api/repair-orders/42")
        return reply({
          order,
          services: [
            {
              id: 11,
              name: service.name,
              quantity: 2,
              unitPrice: 200000,
              status: "DANG_SUA",
            },
          ],
          assignments,
        })
      if (path === "/api/technicians")
        return reply([{ id: 7, fullName: "KTV kiểm thử" }])
      if (path === "/api/repair-orders/42/technicians" && method === "POST") {
        if (conflict)
          return reply(
            null,
            409,
            "Kỹ thuật viên đã được phân công cho phiếu sửa chữa này.",
          )
        const assignment = {
          repairOrderId: 42,
          technician: { id: 7, fullName: "KTV kiểm thử" },
          assignedAt: "2026-10-01T09:00:00",
          notes: request.postDataJSON().notes,
        }
        assignments.push(assignment)
        return reply(assignment, 201)
      }
      return reply(null, 404, "Unexpected test API request")
    },
  )
  return {
    failList: (value: boolean) => {
      failList = value
    },
    conflict: () => {
      conflict = true
    },
  }
}

async function expectNoOverflow(page: Page) {
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= window.innerWidth,
    ),
  ).toBe(true)
  expect(
    await page
      .locator("#admin-content")
      .evaluate((element) => element.scrollWidth <= element.clientWidth),
  ).toBe(true)
}

test("service form supports typing, create, edit and reload", async ({
  page,
}) => {
  await setup(page)
  await page.goto("/admin/services")
  await expect(page.getByRole("heading", { name: service.name })).toBeVisible()
  await expectNoOverflow(page)
  await page.getByRole("button", { name: "Thêm dịch vụ", exact: true }).click()
  await page
    .getByLabel("Tên dịch vụ", { exact: true })
    .pressSequentially("Dich vu moi")
  await expect(page.getByLabel("Tên dịch vụ", { exact: true })).toHaveValue(
    "Dich vu moi",
  )
  await page.getByLabel("Đơn giá (VNĐ)").fill("350000")
  await page.getByRole("button", { name: "Lưu dịch vụ" }).click()
  await expect(page.getByRole("status")).toHaveText("Đã thêm dịch vụ.")
  await page.reload()
  await expect(page.getByRole("heading", { name: "Dich vu moi" })).toBeVisible()
  await page
    .getByRole("button", { name: `Sửa ${service.name}`, exact: true })
    .click()
  await page.getByLabel("Đơn giá (VNĐ)").fill("450000")
  await page.getByRole("button", { name: "Lưu dịch vụ" }).click()
  await expect(page.getByRole("status")).toHaveText("Đã cập nhật dịch vụ.")
  await page.reload()
  await expect(page.getByText(/450\.000/)).toBeVisible()
})

test("service errors can be retried and search has an empty state", async ({
  page,
}) => {
  const state = await setup(page)
  state.failList(true)
  await page.goto("/admin/services")
  await expect(page.getByRole("alert")).toHaveText("Không tải được dịch vụ.")
  state.failList(false)
  await page.getByRole("button", { name: "Thử lại" }).click()
  await expect(page.getByRole("heading", { name: service.name })).toBeVisible()
  await page.getByRole("searchbox").fill("no-match")
  await expect(page.getByText("Không tìm thấy dịch vụ phù hợp.")).toBeVisible()
})

test("manager assigns a technician and the assignment survives reload", async ({
  page,
}) => {
  await setup(page)
  await page.goto("/admin/repair")
  await page.getByRole("button", { name: /Xem phiếu #42/ }).click()
  await expect(page.getByText("Khách kiểm thử", { exact: true })).toBeVisible()
  await expectNoOverflow(page)
  await page.getByRole("button", { name: "Phân công KTV", exact: true }).click()
  await page.getByLabel("Kỹ thuật viên", { exact: true }).selectOption("7")
  await page.getByLabel("Nội dung phân công").fill("Kiểm tra phanh trước")
  await page.getByRole("button", { name: "Xác nhận phân công" }).click()
  await expect(page.getByRole("status")).toHaveText(
    "Đã phân công KTV kiểm thử.",
  )
  await page.reload()
  await page.getByRole("button", { name: /Xem phiếu #42/ }).click()
  await expect(
    page.getByText("Kiểm tra phanh trước", { exact: true }),
  ).toBeVisible()
  await page.getByRole("button", { name: "Phân công KTV", exact: true }).click()
  await expect(
    page.getByText("Không còn kỹ thuật viên nào để thêm vào phiếu này."),
  ).toBeVisible()
  await expect(
    page.getByRole("button", { name: "Xác nhận phân công" }),
  ).toBeDisabled()
})

test("assignment conflict stays in the form without a false success", async ({
  page,
}) => {
  const state = await setup(page)
  state.conflict()
  await page.goto("/admin/repair")
  await page.getByRole("button", { name: /Xem phiếu #42/ }).click()
  await page.getByRole("button", { name: "Phân công KTV", exact: true }).click()
  await page.getByLabel("Kỹ thuật viên", { exact: true }).selectOption("7")
  await page.getByRole("button", { name: "Xác nhận phân công" }).click()
  await expect(page.getByRole("alert")).toContainText("đã được phân công")
  await expect(page.getByRole("dialog")).toBeVisible()
})

for (const role of ["TECHNICIAN", "RECEPTIONIST", "ADMIN"]) {
  test(`${role} has the correct repair-order controls`, async ({ page }) => {
    await setup(page, role)
    await page.goto(
      role === "TECHNICIAN" ? "/admin/technician" : "/admin/repair",
    )
    await page.getByRole("button", { name: /Xem phiếu #42/ }).click()
    await expect(
      page.getByRole("heading", { name: order.licensePlate }),
    ).toBeVisible()
    await expectNoOverflow(page)
    if (role === "ADMIN")
      await expect(
        page.getByRole("button", { name: "Phân công KTV", exact: true }),
      ).toBeVisible()
    else
      await expect(
        page.getByRole("button", { name: "Phân công KTV", exact: true }),
      ).toHaveCount(0)
    await page.getByRole("button", { name: "Quay lại danh sách" }).click()
    await expect(
      page.getByRole("button", { name: /Xem phiếu #42/ }),
    ).toBeVisible()
  })
}
