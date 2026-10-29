import {test,expect,type Page} from "@playwright/test";
import {readFileSync,writeFileSync} from "node:fs";
import {execFileSync} from "node:child_process";

const fixturePath=process.env.GARAGE_VERIFY_CREDENTIALS;
const fixture=fixturePath?JSON.parse(readFileSync(fixturePath,"utf8").replace(/^\uFEFF/,"")):null;
test.skip(!fixture,"Requires the isolated verification server and fixture file.");
async function login(page:Page,person:{username:string;password:string}) {
  await page.goto("/login");
  await page.getByLabel("Tên đăng nhập",{exact:true}).fill(person.username);
  await page.getByLabel("Mật khẩu",{exact:true}).fill(person.password);
  await page.getByRole("button",{name:"Đăng nhập",exact:true}).click();
  await expect(page).not.toHaveURL(/\/login$/);
}
function sql(query:string) {
  if(!/^QuanLyGaraOTo_Verify_\d{8}$/.test(fixture.database)) throw new Error("Not a verification database");
  return execFileSync("sqlcmd",["-S","localhost","-E","-C","-d",fixture.database,"-h","-1","-W","-b","-Q","SET NOCOUNT ON; "+query],{encoding:"utf8"}).trim();
}
test("create on customer Web and confirm on staff Web with SQL persistence",async({page,browser,request},info)=>{
  if(fixture.bookingId) {
    const previous=await request.get(fixture.apiUrl+"/appointments/"+fixture.bookingId,{headers:{Authorization:"Bearer "+fixture.customer.token}});
    if(previous.ok()) {
      const item=(await previous.json()).data;
      if(["CHO_XAC_NHAN","DA_XAC_NHAN"].includes(item.status)) {
        const cancelled=await request.patch(fixture.apiUrl+"/appointments/"+item.id+"/cancel",{
          headers:{Authorization:"Bearer "+fixture.customer.token},data:{version:item.version,reason:"Kết thúc lần kiểm chứng trước"}});
        expect(cancelled.ok()).toBe(true);
      }
    }
  }
  await login(page,fixture.customer);
  await page.goto("/customer/appointments");
  await expect(page.getByText("Dữ liệu minh họa — MOCK_ONLY")).toHaveCount(0);
  await page.getByRole("button",{name:"Đặt lịch mới",exact:true}).click();
  await page.getByLabel("Xe",{exact:true}).selectOption(String(fixture.vehicleId));
  await page.getByLabel("Dịch vụ",{exact:true}).selectOption(String(fixture.serviceId));
  await page.getByLabel("Ngày hẹn",{exact:true}).fill(fixture.date);
  await page.getByLabel("Giờ hẹn (giờ Việt Nam)",{exact:true}).selectOption(fixture.time+":00");
  await page.getByLabel("Yêu cầu của bạn").fill("Kiểm tra phanh trước chuyến đi");
  const responsePromise=page.waitForResponse(r=>r.request().method()==="POST"&&r.url().endsWith("/api/appointments"));
  await page.getByRole("button",{name:"Lưu lịch hẹn",exact:true}).click();
  const response=await responsePromise;expect(response.status()).toBe(201);
  const item=(await response.json()).data;fixture.bookingId=item.id;
  writeFileSync(fixturePath!,JSON.stringify(fixture,null,2));
  await page.reload();
  const row=page.getByRole("row").filter({hasText:"LH"+item.id});
  await expect(row).toContainText(fixture.plate);await expect(row).toContainText("Chờ xác nhận");
  expect(sql("SELECT TrangThai FROM LichHen WHERE MaLichHen="+Number(item.id))).toBe("CHO_XAC_NHAN");
  await page.screenshot({path:info.outputPath("customer-created.png"),fullPage:true});
  const managerContext=await browser.newContext();const staff=await managerContext.newPage();
  await login(staff,fixture.manager);await staff.goto("/admin/appointments");
  const staffRow=staff.getByRole("row").filter({hasText:"LH"+item.id});
  await staffRow.getByRole("button",{name:"Xác nhận",exact:true}).click();
  await staff.getByRole("button",{name:"Lưu lịch hẹn",exact:true}).click();
  await expect(staff.getByRole("dialog")).toHaveCount(0);
  await staff.reload();await expect(staffRow).toContainText("Đã xác nhận");
  expect(sql("SELECT TrangThai FROM LichHen WHERE MaLichHen="+Number(item.id))).toBe("DA_XAC_NHAN");
  await staff.screenshot({path:info.outputPath("staff-confirmed.png"),fullPage:true});
  const denied=await request.get(fixture.apiUrl+"/appointments/"+item.id,{headers:{Authorization:"Bearer "+fixture.otherCustomer.token}});
  expect(denied.status()).toBe(404);
  await managerContext.close();
});
test("reload Web after Flutter reschedule and cancellation",async({page},info)=>{
  expect(fixture.bookingId).toBeGreaterThan(0);
  await login(page,fixture.customer);await page.goto("/customer/appointments");
  const row=page.getByRole("row").filter({hasText:"LH"+fixture.bookingId});
  await expect(row).toContainText("Đã hủy");
  await expect(row).toContainText(fixture.newTime);
  expect(sql("SELECT TrangThai FROM LichHen WHERE MaLichHen="+Number(fixture.bookingId))).toBe("HUY");
  expect(sql("SELECT COUNT(*) FROM LichSuLichHen WHERE MaLichHen="+Number(fixture.bookingId))).toBe("4");
  for(const width of [1440,768,390]) {
    await page.setViewportSize({width,height:1000});
    await page.screenshot({path:info.outputPath("synced-"+width+".png"),fullPage:true});
    expect(await page.evaluate(()=>document.documentElement.scrollWidth<=window.innerWidth)).toBe(true);
  }
});
