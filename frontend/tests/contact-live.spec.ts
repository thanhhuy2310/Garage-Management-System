import { test, expect } from "@playwright/test";
import { readFileSync } from "node:fs";
import { execFileSync } from "node:child_process";

const fixturePath = process.env.GARAGE_VERIFY_CREDENTIALS;
const fixture = fixturePath ? JSON.parse(readFileSync(fixturePath, "utf8").replace(/^\uFEFF/, "")) : null;
test.skip(!fixture, "Requires an isolated verification database");

test("visitor submits a contact message and staff reads it after reloading", async ({ page }) => {
  if (!/^QuanLyGaraOTo_Verify_\d{8}$/.test(fixture.database)) throw new Error("Invalid verification database");
  const sql = (statement: string) => execFileSync("sqlcmd", ["-S", "localhost", "-E", "-C", "-I", "-b", "-d", fixture.database, "-h", "-1", "-W", "-Q", "SET NOCOUNT ON; " + statement], { encoding: "utf8" }).trim();
  const phone = "09" + String(Date.now()).slice(-8);
  await page.goto("/contact");
  await page.getByLabel("Họ tên *", { exact: true }).fill("Nguyễn Minh Hạnh");
  await page.getByLabel("Số điện thoại *", { exact: true }).fill(phone);
  await page.getByLabel("Nội dung *", { exact: true }).fill("Tôi muốn kiểm tra phanh trước chuyến đi.");
  await page.route("**/api/public/contact-messages", route => route.fulfill({ status: 503, contentType: "application/json", body: JSON.stringify({ message: "Chưa gửi được lời nhắn." }) }));
  await page.getByRole("button", { name: "Gửi lời nhắn", exact: true }).click();
  await expect(page.getByRole("alert")).toContainText("Chưa gửi được lời nhắn.");
  await expect(page.getByRole("heading", { name: "Đã nhận lời nhắn" })).toHaveCount(0);
  await page.unroute("**/api/public/contact-messages");
  const posted = page.waitForResponse(r => r.url().endsWith("/api/public/contact-messages") && r.request().method() === "POST");
  await page.getByRole("button", { name: "Gửi lời nhắn", exact: true }).click();
  const response = await posted;
  expect(response.status()).toBe(201);
  const id = Number((await response.json()).data.id);
  expect(Number.isSafeInteger(id) && id > 0).toBe(true);
  const predicate = `MaLienHe=${id} AND SoDienThoai='${phone}'`;
  try {
    await expect(page.getByRole("heading", { name: "Đã nhận lời nhắn" })).toBeVisible();
    expect(sql(`SELECT DaDoc FROM LienHeKhachHang WHERE ${predicate}`)).toBe("0");
    await page.goto("/login");
    await page.getByLabel("Tên đăng nhập", { exact: true }).fill(fixture.manager.username);
    await page.getByLabel("Mật khẩu", { exact: true }).fill(fixture.manager.password);
    await page.getByRole("button", { name: "Đăng nhập", exact: true }).click();
    await expect(page).not.toHaveURL(/\/login$/);
    await page.getByRole("button", { name: "Lời nhắn khách hàng", exact: true }).click();
    const message = page.getByRole("button").filter({ hasText: phone });
    await expect(message).toHaveAttribute("aria-label", /Đánh dấu đã đọc/);
    await message.click();
    await expect(message).toHaveAttribute("aria-label", /Lời nhắn đã đọc/);
    await page.reload();
    await expect(message).toHaveAttribute("aria-label", /Lời nhắn đã đọc/);
    expect(sql(`SELECT DaDoc FROM LienHeKhachHang WHERE ${predicate}`)).toBe("1");
  } finally {
    sql(`DELETE FROM LienHeKhachHang WHERE ${predicate}`);
  }
});
