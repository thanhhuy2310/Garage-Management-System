package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.account.AccountResponse;
import com.gara.quanlygara.dto.auth.ChangePasswordRequest;
import com.gara.quanlygara.dto.auth.LoginRequest;
import com.gara.quanlygara.dto.auth.LoginResponse;
import com.gara.quanlygara.dto.auth.RegisterRequest;
import com.gara.quanlygara.service.AuthService;
import jakarta.validation.Valid;
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

    public AuthController(AuthService authService, JwtService jwt, SessionRevocations revocations) {
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
