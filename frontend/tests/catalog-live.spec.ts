import {test,expect} from "@playwright/test";
test("public services and parts use anonymous APIs and show load errors honestly",async({page,request})=>{
  const servicesResponse=await request.get("/api/public/services");expect(servicesResponse.status()).toBe(200);
  const services=(await servicesResponse.json()).data;
  const partsResponse=await request.get("/api/public/parts?size=100");expect(partsResponse.status()).toBe(200);
  const parts=(await partsResponse.json()).data;
  await page.goto("/services");
  await expect(page.getByRole("heading",{name:"Bảng dịch vụ & giá công khai",exact:true})).toBeVisible();
  if(services.length){
    const service=services[0];await page.getByPlaceholder("Tìm tên dịch vụ...").fill(service.name);
    await expect(page.getByRole("heading",{name:service.name,exact:true}).first()).toBeVisible();
  }
  await page.goto("/parts");
  if(parts.items.length){
    const part=parts.items[0];await page.getByPlaceholder("Tên, hãng, mã phụ tùng...").fill(part.name);
    await expect(page.getByRole("heading",{name:part.name,exact:true}).first()).toBeVisible();
  }
  await page.route("**/api/public/services",route=>route.fulfill({status:503,contentType:"application/json",body:JSON.stringify({success:false,message:"Không tải được danh mục."})}));
  await page.goto("/services");await expect(page.getByRole("alert")).toContainText("Không tải được danh mục.");
  await page.unroute("**/api/public/services");await page.getByRole("button",{name:"Thử lại",exact:true}).click();
  await expect(page.getByRole("alert")).toHaveCount(0);
  if(services.length)await expect(page.getByRole("heading",{name:services[0].name,exact:true}).first()).toBeVisible();
});
