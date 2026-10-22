import { expect, test, type Page } from "@playwright/test"

async function rememberAccount(page: Page, role: string, expired = false) {
  const account = {
    id: 1, username: "returning-user", role, active: true,
    customerId: role === "CUSTOMER" ? 1 : null,
    employeeId: role === "CUSTOMER" ? null : 1,
  }
  await page.addInitScript((account) => {
    if (sessionStorage.getItem("auth-fixture-seeded")) return
    localStorage.setItem("garage_access_token", "browser-test-token")
    localStorage.setItem("garage_account", JSON.stringify(account))
    sessionStorage.setItem("auth-fixture-seeded", "1")
  }, account)
  await page.route("**/api/auth/me", (route) => route.fulfill({
    status: expired ? 401 : 200,
    json: { success: !expired, message: expired ? "Phiên đã hết hạn." : "OK", data: expired ? null : account },
  }))
  await page.route("**/api/auth/logout", (route) => route.fulfill({
    json: { success: true, message: "OK", data: null },
  }))
  await page.route("**/api/services**", (route) => route.fulfill({
    json: { success: true, message: "OK", data: [] },
  }))
  await page.route("**/api/customer/profile", (route) => route.fulfill({
    json: { success: true, data: { id: 1, fullName: "Khách quay lại", phone: "0901234567", email: null, address: null, active: true } },
  }))
}

async function headerAction(page: Page, name: string) {
  const header = page.locator("header")
  const action = header.getByRole("button", { name, exact: true })
  if (!(await action.isVisible())) await header.getByRole("button", { name: "Mở menu" }).click()
  await action.click()
}

async function expectHome(page: Page) {
  await expect(page).toHaveURL(/\/$/)
  await expect(page.locator("main.public-home")).toBeVisible()
  await expect(page.locator("main.public-home h1")).toBeVisible()
}

test("visitors open the homepage, then choose login and can return", async ({ page }) => {
  await page.goto("/", { waitUntil: "domcontentloaded" })
  await expectHome(page)
  await headerAction(page, "Đăng nhập")
  await expect(page).toHaveURL(/\/login$/)
  await expect(page.getByRole("heading", { name: "Đăng nhập", exact: true })).toBeVisible()
  await page.getByRole("button", { name: "Về trang chủ" }).click()
  await expectHome(page)
})

for (const role of ["MANAGER", "ADMIN", "RECEPTIONIST", "TECHNICIAN", "WAREHOUSE", "CUSTOMER"]) {
  test(`remembered ${role} stays on homepage after opening and reloading`, async ({ page }) => {
    await rememberAccount(page, role)
    await page.goto("/", { waitUntil: "domcontentloaded" })
    await expectHome(page)
    await page.reload({ waitUntil: "domcontentloaded" })
    await expectHome(page)
    await expect.poll(() => page.evaluate(() => localStorage.getItem("garage_access_token"))).toBe("browser-test-token")
  })
}

test("remembered manager can browse public pages, enter management and go back", async ({ page }) => {
  await rememberAccount(page, "MANAGER")
  await page.goto("/", { waitUntil: "domcontentloaded" })
  await expectHome(page)
  await headerAction(page, "Dịch vụ")
  await expect(page).toHaveURL(/\/services$/)
  await headerAction(page, "Quản lý")
  await expect(page).toHaveURL(/\/admin\/dashboard$/)
  await page.goBack()
  await expect(page).toHaveURL(/\/services$/)
  await page.goBack()
  await expectHome(page)
})

test("customer can book from homepage without logging in again", async ({ page }) => {
  await rememberAccount(page, "CUSTOMER")
  await page.goto("/", { waitUntil: "domcontentloaded" })
  await expectHome(page)
  await headerAction(page, "Đặt lịch")
  await expect(page).toHaveURL(/\/customer\/appointments$/)
  await page.goBack()
  await expectHome(page)
})

test("expired remembered session does not take visitors away from homepage", async ({ page }) => {
  await rememberAccount(page, "MANAGER", true)
  await page.goto("/", { waitUntil: "domcontentloaded" })
  await expectHome(page)
  await expect.poll(() => page.evaluate(() => localStorage.getItem("garage_access_token"))).toBeNull()
  await expectHome(page)
  await headerAction(page, "Đăng nhập")
  await expect(page).toHaveURL(/\/login$/)
})

test("protected deep links and role restrictions are preserved", async ({ page }) => {
  await rememberAccount(page, "MANAGER")
  await page.goto("/admin/services", { waitUntil: "domcontentloaded" })
  await expect(page).toHaveURL(/\/admin\/services$/)
  await expect(page.getByRole("heading", { name: "Danh mục dịch vụ" })).toBeVisible()
  await page.goto("/admin/settings", { waitUntil: "domcontentloaded" })
  await expect(page).toHaveURL(/\/admin\/dashboard$/)
})

test("expired sessions still require login on a protected page", async ({ page }) => {
  await rememberAccount(page, "MANAGER", true)
  await page.goto("/admin/services", { waitUntil: "domcontentloaded" })
  await expect(page).toHaveURL(/\/login$/)
  await expect(page.getByRole("heading", { name: "Đăng nhập", exact: true })).toBeVisible()
  await expect.poll(() => page.evaluate(() => localStorage.getItem("garage_access_token"))).toBeNull()
})

test("logout returns to homepage and does not restore the session on reload", async ({ page }) => {
  await rememberAccount(page, "MANAGER")
  await page.goto("/admin/dashboard", { waitUntil: "domcontentloaded" })
  await expect(page.locator("header").getByRole("heading", { name: "Tổng quan", exact: true })).toBeVisible()
  const logout = page.getByRole("button", { name: "Đăng xuất", exact: true })
  const menu = page.getByRole("button", { name: "Mở thanh điều hướng", exact: true })
  if (await menu.isVisible()) await menu.click()
  await logout.click()
  await expectHome(page)
  await expect.poll(() => page.evaluate(() => localStorage.getItem("garage_access_token"))).toBeNull()
  await page.reload({ waitUntil: "domcontentloaded" })
  await expectHome(page)
  await headerAction(page, "Đăng nhập")
  await expect(page).toHaveURL(/\/login$/)
})
