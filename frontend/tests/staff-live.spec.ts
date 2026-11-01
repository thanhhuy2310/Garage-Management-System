import {test,expect} from "@playwright/test";
import {readFileSync} from "node:fs";
import {execFileSync} from "node:child_process";
const path=process.env.GARAGE_VERIFY_CREDENTIALS;
const f=path?JSON.parse(readFileSync(path,"utf8").replace(/^\uFEFF/,"")):null;
test.skip(!f,"Requires isolated SQL Server verification credentials.");
function sql(query:string){
  if(!/^QuanLyGaraOTo_Verify_\d{8}$/.test(f.database))throw new Error("Not a verification database");
  return execFileSync("sqlcmd",["-S","localhost","-E","-C","-I","-d",f.database,"-h","-1","-W","-b","-Q","SET NOCOUNT ON; "+query],{encoding:"utf8"}).trim();
}
test("staff Web persists a technician and updates after reload",async({page})=>{
  await page.goto("/login");
  await page.getByLabel("Tên đăng nhập",{exact:true}).fill(f.manager.username);
  await page.getByLabel("Mật khẩu",{exact:true}).fill(f.manager.password);
  await page.getByRole("button",{name:"Đăng nhập",exact:true}).click();
  await expect(page).not.toHaveURL(/\/login$/);
  await page.goto("/admin/staff");
  await expect(page.getByText(/MOCK_ONLY/)).toHaveCount(0);
  await page.getByRole("button",{name:"Thêm nhân viên",exact:true}).click();
  const dialog=page.getByRole("dialog");
  const phone="09"+Date.now().toString().slice(-8);
  await dialog.getByLabel("Họ và tên *",{exact:true}).fill("Trần Đức Thành");
  await dialog.getByLabel("Số điện thoại",{exact:true}).fill(phone);
  await dialog.getByLabel("Email",{exact:true}).fill("ducthanh@example.com");
  await dialog.getByLabel("Chức vụ *",{exact:true}).fill("Kỹ thuật viên máy gầm");
  await dialog.getByLabel("Khai báo kỹ thuật viên",{exact:true}).check();
  const created=page.waitForResponse(r=>r.request().method()==="POST"&&r.url().endsWith("/api/employees"));
  await dialog.getByRole("button",{name:"Lưu nhân viên",exact:true}).click();
  const response=await created;expect(response.status()).toBe(201);const id=Number((await response.json()).data.id);
  try {
    await expect(dialog).toHaveCount(0);
    expect(sql("SELECT COUNT(*) FROM NhanVien e JOIN KyThuatVien t ON t.MaNhanVien=e.MaNhanVien WHERE e.MaNhanVien="+id)).toBe("1");
    await page.reload();await page.getByLabel("Tìm nhân viên").fill(phone);
    await page.getByRole("button").filter({hasText:phone}).click();
    await expect(page.getByText("Chưa có tài khoản",{exact:true})).toBeVisible();
    await page.getByRole("button",{name:"Chỉnh sửa",exact:true}).click();
    await dialog.getByLabel("Số điện thoại",{exact:true}).fill("08"+phone.slice(2));
    await dialog.getByRole("button",{name:"Lưu nhân viên",exact:true}).click();
    await expect(dialog).toHaveCount(0);
    await page.reload();await page.getByLabel("Tìm nhân viên").fill("08"+phone.slice(2));
    await expect(page.getByRole("button").filter({hasText:"08"+phone.slice(2)})).toBeVisible();
    expect(sql("SELECT SoDienThoai FROM NhanVien WHERE MaNhanVien="+id)).toBe("08"+phone.slice(2));
  } finally {
    sql("BEGIN TRAN; DELETE FROM KyThuatVien WHERE MaNhanVien="+id+"; DELETE FROM NhanVien WHERE MaNhanVien="+id+"; COMMIT;");
  }
});
