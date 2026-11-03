package com.gara.quanlygara.bootstrap;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.regex.Pattern;

@Component
@ConditionalOnProperty(name = "app.bootstrap.admin.enabled", havingValue = "true")
public class InitialAdminBootstrap implements ApplicationRunner {
    private static final Pattern USERNAME = Pattern.compile("[A-Za-z0-9._-]{4,50}");

    private final JdbcTemplate jdbc;
    private final PasswordEncoder passwords;
    private final String username;
    private final String password;
    private final String fullName;
    private final String email;

    public InitialAdminBootstrap(
            JdbcTemplate jdbc,
            PasswordEncoder passwords,
            @Value("${app.bootstrap.admin.username:}") String username,
            @Value("${app.bootstrap.admin.password:}") String password,
            @Value("${app.bootstrap.admin.full-name:}") String fullName,
            @Value("${app.bootstrap.admin.email:}") String email
    ) {
        this.jdbc = jdbc;
        this.passwords = passwords;
        this.username = username.trim();
        this.password = password;
        this.fullName = fullName.trim();
        this.email = email.trim();
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        Integer adminCount = jdbc.queryForObject(
                "SELECT COUNT(*) FROM TaiKhoan WITH (UPDLOCK,HOLDLOCK) WHERE VaiTro = N'ADMIN'", Integer.class);
        if (adminCount != null && adminCount > 0) {
            throw new IllegalStateException(
                    "Bootstrap admin bị từ chối vì database đã có tài khoản ADMIN. Hãy tắt BOOTSTRAP_ADMIN_ENABLED.");
        }
        validateInput();

        Integer usernameCount = jdbc.queryForObject(
                "SELECT COUNT(*) FROM TaiKhoan WHERE TenDangNhap = ?", Integer.class, username);
        if (usernameCount != null && usernameCount > 0) {
            throw new IllegalStateException("Tên đăng nhập bootstrap đã tồn tại.");
        }

        Integer employeeId = jdbc.queryForObject("""
                INSERT INTO NhanVien (HoTen, Email, ChucVu) OUTPUT INSERTED.MaNhanVien
                VALUES (?, NULLIF(?, ''), N'QUAN_TRI_VIEN');
                """, Integer.class, fullName, email);

        jdbc.update("""
                INSERT INTO TaiKhoan (TenDangNhap, MatKhauHash, VaiTro, TrangThai, MaKhachHang, MaNhanVien)
                VALUES (?, ?, N'ADMIN', 1, NULL, ?)
                """, username, passwords.encode(password), employeeId);
    }

    private void validateInput() {
        if (!USERNAME.matcher(username).matches()) {
            throw new IllegalStateException(
                    "BOOTSTRAP_ADMIN_USERNAME phải có 4-50 ký tự gồm chữ, số, dấu chấm, gạch dưới hoặc gạch ngang.");
        }
        if (password.length() < 12 || password.getBytes(java.nio.charset.StandardCharsets.UTF_8).length > 72
                || password.equalsIgnoreCase("demo123") || password.equalsIgnoreCase("password")) {
            throw new IllegalStateException(
                    "BOOTSTRAP_ADMIN_PASSWORD phải có 12-72 ký tự và không được dùng mật khẩu mẫu.");
        }
        if (fullName.length() < 2 || fullName.length() > 100) {
            throw new IllegalStateException("BOOTSTRAP_ADMIN_FULL_NAME phải có 2-100 ký tự.");
        }
    }
}
