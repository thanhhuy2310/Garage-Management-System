import {test,expect,chromium} from "@playwright/test";
import {readFileSync,mkdtempSync} from "node:fs";
import {tmpdir} from "node:os";
import {join} from "node:path";

const file=process.env.GARAGE_VERIFY_CREDENTIALS;
test.skip(!file,"Requires the isolated SQL verification environment.");
test("remembered cookie survives a Chrome restart and logout invalidates it",async({request})=>{
  const account=JSON.parse(readFileSync(file!,"utf8").replace(/^\uFEFF/,"")).customer;
  const profile=mkdtempSync(join(tmpdir(),"garage-remember-"));
  const launch=()=>chromium.launchPersistentContext(profile,{channel:"chrome",baseURL:"http://127.0.0.1:5188"});
  let context=await launch();
  try {
    let page=await context.newPage();await page.goto("/login");
    await page.getByLabel("Tên đăng nhập",{exact:true}).fill(account.username);
    await page.getByLabel("Mật khẩu",{exact:true}).fill(account.password);
    await page.getByLabel("Ghi nhớ đăng nhập").check();
    await page.getByRole("button",{name:"Đăng nhập",exact:true}).click();await expect(page).not.toHaveURL(/\/login$/);
    const cookie=(await context.cookies()).find(c=>c.name==="garage_session");
    expect(cookie?.httpOnly).toBe(true);expect(cookie!.expires).toBeGreaterThan(Date.now()/1000);
    expect(await page.evaluate(()=>localStorage.getItem("garage_access_token"))).toBeNull();
    await context.close();context=await launch();page=await context.newPage();await page.goto("/login");
    await expect(page).toHaveURL(/\/customer/);
    const done=page.waitForResponse(r=>r.url().endsWith("/auth/logout"));
    await page.getByRole("button",{name:"Đăng xuất",exact:true}).first().click();
    expect((await done).ok()).toBeTruthy();
    const replay=await request.get("/api/auth/me",{headers:{Cookie:"garage_session="+cookie!.value,"X-Garage-Client":"web"}});
    expect(replay.status()).toBe(401);
  } finally {await context.close();}
});
