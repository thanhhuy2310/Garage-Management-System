# Backend - Garage Management

Java Spring Boot REST API cho hệ thống quản lý gara sửa chữa ô tô.

## Stack
- Java 21
- Spring Boot 3
- Spring Web
- Spring Data JPA
- Bean Validation
- SQL Server
- Maven

## Chạy backend trong IntelliJ IDEA
1. Mở thư mục gốc `garage-management-system` bằng IntelliJ IDEA.
2. IntelliJ sẽ nhận `backend/pom.xml` là Maven project. Nếu chưa nhận, nhấn phải `pom.xml` -> **Add as Maven Project**.
3. Chọn JDK 21.
4. Sửa cấu hình SQL Server trong `src/main/resources/application.properties`.
5. Chạy class `com.gara.quanlygara.QuanLyGaraApplication`.
6. API test: `http://localhost:8080/api/health`.

Script SQL hiện nằm tại `database/QuanLyGaraOTo.sql`.
