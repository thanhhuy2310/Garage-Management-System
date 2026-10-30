import { defineConfig } from "@playwright/test";
export default defineConfig({
  testDir:"./tests",testMatch:/(appointments|quotations)-live\.spec\.ts/,workers:1,
  use:{baseURL:"http://127.0.0.1:5188",channel:"chrome",viewport:{width:1440,height:1000},
    screenshot:"only-on-failure",trace:"off"},
  webServer:{
    command:"node node_modules/vite/bin/vite.js --host 127.0.0.1 --port 5188 --strictPort",
    url:"http://127.0.0.1:5188",reuseExistingServer:false,
    env:{BROWSER:"none",GARAGE_API_TARGET:"http://127.0.0.1:8088"},
  },
});
