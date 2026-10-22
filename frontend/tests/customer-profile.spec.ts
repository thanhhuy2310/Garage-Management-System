import { expect, test, type Page } from "@playwright/test"

// Isolated browser fixtures; the portal itself loads the authenticated SQL profile.
async function setup(page: Page, customerId: number, fullName: string) {
  const account = { id: customerId, username: `customer-${customerId}`, role: "CUSTOMER", active: true, customerId, employeeId: null }
  const state = { fail: false, fullName }
  await page.addInitScript((account) => {
    localStorage.setItem("garage_access_token", "profile-test-token")
    localStorage.setItem("garage_account", JSON.stringify(account))
  }, account)
  await page.route("**/api/auth/me", (route) => route.fulfill({
    json: { success: true, data: account },
  }))
  await page.route("**/api/customer/profile", (route) => route.fulfill({
    status: state.fail ? 500 : 200,
    json: state.fail
      ? { success: false, message: "Không tải được hồ sơ. Vui lòng thử lại.", data: null }
      : { success: true, data: { id: customerId, fullName: state.fullName, phone: "0901234567", email: "customer@example.test", address: "TP. Hồ Chí Minh", active: true } },
  }))
  await page.route("**/api/customers/*/vehicles", route => route.fulfill({json: {success: true, data: []}}))
  await page.route("**/api/customer/repairs", route => route.fulfill({json: {success: true, data: []}}))
  return state
}

for (const [id, name] of [[2, "Trần Minh Tuấn"], [31, "Đỗ Khánh Vy"]] as const) {
  test(`greeting and profile use SQL customer ${id}, not matching mock ID`, async ({ page }) => {
    const state = await setup(page, id, name)
    await page.goto("/customer")
    await expect(page.locator("header")).toContainText(`Xin chào, ${name}`)
    await page.getByRole("tab", { name: "Hồ sơ", exact: true }).click()
    await expect(page.locator("#customer-content")).toContainText(name)
    await expect(page.locator("#customer-content")).toContainText("customer@example.test")
    await expect(page.getByText("Vũ Thị Phương", { exact: true })).toHaveCount(0)
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)

    state.fullName = `${name} Anh`
    await page.reload()
    await expect(page.locator("header")).toContainText(`Xin chào, ${state.fullName}`)
    await expect(page.locator("#customer-content")).toContainText(state.fullName)
  })
}

test("failed profile request never falls back to someone else's mock name and can retry", async ({ page }) => {
  const state = await setup(page, 2, "Trần Minh Tuấn")
  state.fail = true
  await page.goto("/customer/profile")
  await expect(page.getByRole("alert")).toHaveText("Không tải được hồ sơ. Vui lòng thử lại.")
  await expect(page.locator("header")).toContainText("Xin chào, Khách hàng")
  await expect(page.getByRole("heading", { name: "Thông tin cá nhân" })).toHaveCount(0)
  state.fail = false
  await page.getByRole("button", { name: "Thử lại", exact: true }).click()
  await expect(page.locator("header")).toContainText("Xin chào, Trần Minh Tuấn")
  await expect(page.getByRole("heading", { name: "Thông tin cá nhân" })).toBeVisible()
  await expect(page.getByRole("alert")).toHaveCount(0)
})
