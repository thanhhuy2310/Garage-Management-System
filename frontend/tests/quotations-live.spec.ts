import {test,expect,type Page} from "@playwright/test";
import {readFileSync,writeFileSync} from "node:fs";
import {execFileSync} from "node:child_process";
const path=process.env.GARAGE_VERIFY_CREDENTIALS;
const f=path?JSON.parse(readFileSync(path,"utf8").replace(/^\uFEFF/,"")):null;
test.skip(!f,"Requires an isolated SQL Server verification fixture.");
async function login(page:Page,person:{username:string;password:string}){
  await page.goto("/login");await page.getByLabel("Tên đăng nhập",{exact:true}).fill(person.username);
  await page.getByLabel("Mật khẩu",{exact:true}).fill(person.password);
  await page.getByRole("button",{name:"Đăng nhập",exact:true}).click();await expect(page).not.toHaveURL(/\/login$/);
}
function sql(query:string){
  if(!/^QuanLyGaraOTo_Verify_\d{8}$/.test(f.database))throw new Error("Not a verification database");
  return execFileSync("sqlcmd",["-S","localhost","-E","-C","-I","-d",f.database,"-h","-1","-W","-b","-Q","SET NOCOUNT ON; "+query],{encoding:"utf8"}).trim();
}
async function confirm(page:Page){await page.getByRole("button",{name:"Xác nhận thao tác",exact:true}).click();await expect(page.getByRole("dialog")).toHaveCount(0);}
async function selectQuote(page:Page){await page.getByRole("button").filter({hasText:`BG${f.quoteId} · ${f.plate}`}).click();}
test("quotation stage 1 Web creates and sends real quote for Android",async({page,browser})=>{
  await login(page,f.manager);await page.goto("/admin/quotation");
  await expect(page.getByText(/MOCK_ONLY/)).toHaveCount(0);
  await page.getByRole("button",{name:"Tạo báo giá",exact:true}).click();
  await page.getByLabel("Phiếu sửa chữa",{exact:true}).selectOption(String(f.quotationOrderId));
  await expect(page.getByLabel("Hạng mục 1",{exact:true})).toHaveValue(String(f.serviceId));
  const price=page.getByLabel("Đơn giá 1",{exact:true});
  await expect(price).toHaveAttribute("step","1000");
  await price.fill("150001");
  expect(await price.evaluate((input:HTMLInputElement)=>input.validity.stepMismatch)).toBe(true);
  await price.fill("150000");
  await page.getByRole("button",{name:"Thêm hạng mục",exact:true}).click();
  await page.getByLabel("Loại hạng mục 2",{exact:true}).selectOption("PART");
  await page.getByLabel("Hạng mục 2",{exact:true}).selectOption(String(f.quotationPartId));
  const created=page.waitForResponse(r=>r.request().method()==="POST"&&r.url().endsWith("/api/quotations"));
  await page.getByRole("button",{name:"Lưu bản nháp",exact:true}).click();
  const response=await created;expect(response.status()).toBe(201);f.quoteId=(await response.json()).data.id;
  writeFileSync(path!,JSON.stringify(f,null,2));
  await expect(page.getByRole("dialog")).toHaveCount(0);
  await page.getByRole("button",{name:"Gửi khách xác nhận",exact:true}).click();await confirm(page);
  await page.reload();await selectQuote(page);
  expect(sql("SELECT CONCAT(TrangThai,':',CONVERT(VARCHAR,TongTien)) FROM BaoGia WHERE MaBaoGia="+Number(f.quoteId))).toBe("CHO_XAC_NHAN:200000.00");
  expect(sql("SELECT COUNT(*) FROM ChiTietBaoGia WHERE MaBaoGia="+Number(f.quoteId))).toBe("2");

  const context=await browser.newContext();const customer=await context.newPage();await login(customer,f.customer);await customer.goto("/customer/quotations");await selectQuote(customer);
  await expect(customer.getByRole("button",{name:"Chấp thuận báo giá",exact:true})).toBeVisible();
  await expect(customer.getByText("200.000 ₫",{exact:true})).toHaveCount(2);
  await context.close();
});
test("quotation stage 2 Web revises after Android rejection",async({page})=>{
  await login(page,f.manager);await page.goto("/admin/quotation");await selectQuote(page);
  expect(sql("SELECT TrangThai FROM BaoGia WHERE MaBaoGia="+Number(f.quoteId))).toBe("KHONG_DONG_Y");
  await expect(page.getByText(/Lý do từ chối:/)).toContainText("Xem lại số lượng dịch vụ");
  await page.getByRole("button",{name:"Tạo lần điều chỉnh",exact:true}).click();await page.getByLabel("Lý do điều chỉnh").fill("Bổ sung kiểm tra theo trao đổi với khách");await confirm(page);
  await page.getByRole("button",{name:"Sửa bản nháp",exact:true}).click();await page.getByLabel("Số lượng 1",{exact:true}).fill("2");
  await page.getByRole("button",{name:"Lưu bản nháp",exact:true}).click();await expect(page.getByRole("dialog")).toHaveCount(0);
  await page.getByRole("button",{name:"Gửi khách xác nhận",exact:true}).click();await confirm(page);
  expect(sql("SELECT CONCAT(TrangThai,':',PhienBan,':',LanDieuChinh,':',CONVERT(VARCHAR,TongTien)) FROM BaoGia WHERE MaBaoGia="+Number(f.quoteId))).toBe("CHO_XAC_NHAN:5:2:350000.00");

});
test("quotation stage 3 Web reloads Android approval and immutable history",async({page})=>{
  await login(page,f.manager);await page.goto("/admin/quotation");await selectQuote(page);
  expect(sql("SELECT CONCAT(TrangThai,':',PhienBan) FROM BaoGia WHERE MaBaoGia="+Number(f.quoteId))).toBe("DA_XAC_NHAN:6");
  expect(sql("SELECT COUNT(*) FROM LichSuBaoGia WHERE MaBaoGia="+Number(f.quoteId))).toBe("7");
  expect(sql("SELECT JSON_VALUE(NoiDung,'$.total') FROM LichSuBaoGia WHERE MaBaoGia="+Number(f.quoteId)+" AND PhienBan=2")).toBe("200000.00");
  await page.getByRole("button",{name:"Lịch sử thay đổi",exact:true}).click();
  await page.getByRole("button").filter({hasText:"Lần 1 · Đã từ chối"}).click();
  await expect(page.getByText("Đang xem nội dung đã lưu trong lịch sử.")).toBeVisible();
  await page.getByRole("button",{name:"Về bản hiện hành",exact:true}).click();
  for(const width of [1440,768,390]){
    await page.setViewportSize({width,height:1000});
    if(width<1280) await expect.poll(()=>page.locator("aside").evaluate(el=>el.getBoundingClientRect().right)).toBeLessThanOrEqual(0);
    await page.getByRole("heading",{name:`Báo giá BG${f.quoteId}`,exact:true}).scrollIntoViewIfNeeded();

    expect(await page.evaluate(()=>document.documentElement.scrollWidth<=window.innerWidth)).toBe(true);
  }
});
