package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.account.AccountResponse;
import com.gara.quanlygara.dto.auth.ChangePasswordRequest;
import com.gara.quanlygara.dto.auth.LoginRequest;
import com.gara.quanlygara.dto.auth.LoginResponse;
import com.gara.quanlygara.dto.auth.RegisterRequest;
import com.gara.quanlygara.service.AuthService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import com.gara.quanlygara.service.PasswordRecovery;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.security.JwtService;
import com.gara.quanlygara.security.SessionRevocations;
import com.gara.quanlygara.security.BrowserSession;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    private final JwtService jwt;
    private final SessionRevocations revocations;

    private final PasswordRecovery recovery;
    public AuthController(AuthService authService, JwtService jwt, SessionRevocations revocations,PasswordRecovery recovery) {
        this.recovery=recovery;
        this.jwt=jwt;
        this.revocations=revocations;
        this.authService = authService;
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@Valid @RequestBody LoginRequest request, HttpServletRequest http,
            @RequestParam(defaultValue="false") boolean remember) {
        return signedIn(authService.login(request), http, remember, HttpStatus.OK, "Đăng nhập thành công.");
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<LoginResponse>> register(@Valid @RequestBody RegisterRequest request, HttpServletRequest http) {
        return signedIn(authService.register(request), http, false, HttpStatus.CREATED, "Đăng ký tài khoản thành công.");
    }

    private ResponseEntity<ApiResponse<LoginResponse>> signedIn(LoginResponse login, HttpServletRequest http, boolean remember, HttpStatus status, String message) {
        var result=ResponseEntity.status(status).cacheControl(org.springframework.http.CacheControl.noStore());
        if (BrowserSession.isBrowser(http)) {
            result.header(HttpHeaders.SET_COOKIE,BrowserSession.cookie(http,login.accessToken(),remember ? login.expiresIn() : -1).toString());
            login=new LoginResponse(null,login.tokenType(),login.expiresIn(),login.account());
        }
        return result.body(ApiResponse.success(message,login));
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(HttpServletRequest http, Authentication auth) {
        String token=BrowserSession.token(http);
        if(token!=null) revocations.revoke(token,jwt.expiresAt(token),auth.getName());
        var result=ResponseEntity.ok();
        if(BrowserSession.isBrowser(http)) result.header(HttpHeaders.SET_COOKIE,BrowserSession.cookie(http,"",0).toString());
        return result.body(ApiResponse.success("Đăng xuất thành công."));
    }

    public record ResetEmail(@NotBlank @Email @Size(max=150) String email) {}
    public record VerifyCode(@NotBlank @Email @Size(max=150) String email,@NotBlank @Pattern(regexp="[0-9]{6}") String code) {}
    public record ResetPassword(@NotBlank @Email @Size(max=150) String email,@NotBlank @Pattern(regexp="[a-f0-9]{64}") String ticket,
                                @NotBlank @Size(min=8,max=72) String password,@NotBlank @Size(max=72) String confirmation) {}
    @PostMapping("/recovery/request")
    public ResponseEntity<ApiResponse<Void>> requestCode(@Valid @RequestBody ResetEmail input) {
        return switch(recovery.request(input.email())) {
            case ACCEPTED -> ResponseEntity.accepted().body(ApiResponse.success("Nếu email liên kết với một tài khoản, bạn sẽ nhận được mã xác minh."));
            case LIMITED -> ResponseEntity.status(429).body(ApiResponse.error("Đã đạt giới hạn gửi mã. Vui lòng thử lại sau.",null));
            case UNAVAILABLE -> ResponseEntity.status(503).body(ApiResponse.error("Dịch vụ gửi email chưa được cấu hình. Vui lòng liên hệ gara.",null));
        };
    }
    @PostMapping("/recovery/verify")
    public ResponseEntity<ApiResponse<String>> verifyCode(@Valid @RequestBody VerifyCode input) {
        String ticket=recovery.verify(input.email(),input.code());
        if(ticket==null) throw new BadRequestException("Mã không hợp lệ hoặc đã hết hạn.");
        return ResponseEntity.ok().cacheControl(org.springframework.http.CacheControl.noStore()).body(ApiResponse.success("Đã xác minh.",ticket));
    }
    @PostMapping("/recovery/complete")
    public ApiResponse<Void> resetPassword(@Valid @RequestBody ResetPassword input) {
        if(!input.password().equals(input.confirmation()) || input.password().getBytes(java.nio.charset.StandardCharsets.UTF_8).length>72)
            throw new BadRequestException("Mật khẩu xác nhận phải khớp và mật khẩu không vượt quá 72 byte.");
        if(!recovery.complete(input.email(),input.ticket(),input.password())) throw new BadRequestException("Yêu cầu khôi phục không còn hiệu lực.");
        return ApiResponse.success("Đã đổi mật khẩu. Vui lòng đăng nhập lại.");
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<AccountResponse>> me(Authentication authentication) {
        return ResponseEntity.ok(ApiResponse.success(
                "Lấy thông tin tài khoản thành công.",
                authService.getCurrentUser(authentication.getName())
        ));
    }

    @PutMapping("/change-password")
    public ResponseEntity<ApiResponse<Void>> changePassword(
            Authentication authentication,
            @Valid @RequestBody ChangePasswordRequest request
    ) {
        authService.changePassword(authentication.getName(), request);
        return ResponseEntity.ok(ApiResponse.success("Đổi mật khẩu thành công."));
    }
}
