# Frontend - Garage Management

Frontend React + TypeScript + Vite lấy từ giao diện Figma Make của hệ thống gara.

## Chạy frontend
Yêu cầu Node.js 20+ và npm.

```bash
cd frontend
npm install
npm run dev
```

Mặc định Vite chạy tại `http://localhost:5173`.

Frontend gửi request đến `/api`; Vite chuyển tiếp request sang Spring Boot tại `http://localhost:8080`. Hãy chạy backend trước khi đăng nhập.
