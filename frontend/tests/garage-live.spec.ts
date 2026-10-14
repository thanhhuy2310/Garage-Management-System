import { expect, test } from "@playwright/test"

test("real SQL services and repair orders render without mock data", async ({
  page,
  request,
}) => {
  const username = process.env.GARAGE_TEST_USERNAME
  const password = process.env.GARAGE_TEST_PASSWORD
  test.skip(
    !username || !password,
    "Set GARAGE_TEST_USERNAME and GARAGE_TEST_PASSWORD to run the read-only SQL smoke test.",
  )

  const login = await request.post("/api/auth/login", {
    data: { username, password },
  })
  expect(login.ok()).toBe(true)
  const { data: session } = await login.json()
  expect(["MANAGER", "ADMIN"]).toContain(session.account.role)
  await page.addInitScript((session) => {
    localStorage.setItem("garage_access_token", session.accessToken)
    localStorage.setItem("garage_account", JSON.stringify(session.account))
  }, session)
  const headers = { Authorization: `Bearer ${session.accessToken}` }
  const serviceResponse = await request.get("/api/services", { headers })
  expect(serviceResponse.ok()).toBe(true)
  const { data: services } = await serviceResponse.json()
  const errors: string[] = []
  page.on("pageerror", (error) => errors.push(error.message))
  await page.goto("/admin/services")
  if (services.length)
    await expect(
      page
        .getByRole("heading", { name: services[0].name, exact: true })
        .first(),
    ).toBeVisible()
  else
    await expect(
      page.getByText("Chưa có dịch vụ. Thêm dịch vụ đầu tiên để bắt đầu."),
    ).toBeVisible()
  await page.getByRole("button", { name: "Thêm dịch vụ", exact: true }).click()
  await page
    .getByLabel("Tên dịch vụ", { exact: true })
    .fill("Chỉ kiểm tra nhập liệu, không lưu")
  await page.getByRole("button", { name: "Hủy", exact: true }).click()

  const orderResponse = await request.get("/api/repair-orders", { headers })
  expect(orderResponse.ok()).toBe(true)
  const { data: orders } = await orderResponse.json()
  await page.goto("/admin/repair")
  if (orders.length) {
    await page
      .getByRole("button", {
        name: `Xem phiếu #${orders[0].id} · ${orders[0].licensePlate}`,
        exact: true,
      })
      .click()
    await expect(
      page.getByRole("heading", { name: orders[0].licensePlate, exact: true }),
    ).toBeVisible()
    if (!["HOAN_TAT", "HUY", "DA_HUY"].includes(orders[0].status)) {
      await page
        .getByRole("button", { name: "Phân công KTV", exact: true })
        .click()
      await expect(page.getByRole("dialog")).toBeVisible()
      await page.getByRole("button", { name: "Hủy", exact: true }).click()
    }
  } else {
    await expect(page.getByText("Chưa có phiếu sửa chữa.")).toBeVisible()
  }
  for (const width of [1440, 768, 390]) {
    await page.setViewportSize({ width, height: 1000 })
    expect(
      await page
        .locator("#admin-content")
        .evaluate((element) => element.scrollWidth <= element.clientWidth),
    ).toBe(true)
    await page.screenshot({
      path: test.info().outputPath(`repair-${width}.png`),
      fullPage: true,
    })
  }
  expect(errors).toEqual([])
  const invoiceResponse = await request.get("/api/invoices", { headers })
  expect(invoiceResponse.ok()).toBe(true)
  const { data: invoices } = await invoiceResponse.json()
  await page.goto("/admin/invoice")
  if (invoices.length) {
    await expect(
      page.getByRole("heading", {
        name: `Hóa đơn #${invoices[0].id}`,
        exact: true,
      }),
    ).toBeVisible()
    await expect(
      page.getByText(invoices[0].licensePlate, { exact: true }),
    ).toBeVisible()
  }
  await page
    .getByRole("button", { name: "Tài khoản ngân hàng", exact: true })
    .click()
  await expect(page.getByLabel("Số tài khoản", { exact: true })).toBeVisible()
  await page.getByRole("button", { name: "Đóng hộp thoại" }).click()
  expect(errors).toEqual([])
})
