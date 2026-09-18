# Garage Management System

Project được chia thành đúng 2 phần chính:

```text
garage-management-system/
├── frontend/   # React + TypeScript + Vite
└── backend/    # Java Spring Boot + SQL Server
```

## 1. Frontend
Giao diện Web được lấy từ project Figma Make hiện tại.

Chạy:
```bash
cd frontend
pnpm install
pnpm dev
```

## 2. Backend
Backend Java Spring Boot.

Trong IntelliJ IDEA:
- mở thư mục gốc `garage-management-system`;
- import `backend/pom.xml` dưới dạng Maven project;
- chọn JDK 21;
- cấu hình SQL Server trong `backend/src/main/resources/application.properties`;
- chạy `QuanLyGaraApplication`.

API kiểm tra:
```text
http://localhost:8080/api/health
```

## Cấu trúc chính
```text
garage-management-system/
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── App.tsx
│   │   └── main.tsx
│   ├── package.json
│   └── vite.config.ts
│
└── backend/
    ├── src/
    │   ├── main/
    │   │   ├── java/com/gara/quanlygara/
    │   │   └── resources/application.properties
    │   └── test/
    ├── database/QuanLyGaraOTo.sql
    └── pom.xml
```
