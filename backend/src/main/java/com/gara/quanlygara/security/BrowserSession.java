package com.gara.quanlygara.security;

import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseCookie;

public final class BrowserSession {
    private static final String NAME = "garage_session";
    private BrowserSession() {}

    public static boolean isBrowser(HttpServletRequest request) {
        return "web".equals(request.getHeader("X-Garage-Client"));
    }

    public static String token(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) return header.substring(7);
        // The custom header requires a successful CORS preflight for cross-origin requests.
        if (isBrowser(request) && request.getCookies() != null) {
            for (Cookie cookie : request.getCookies()) if (NAME.equals(cookie.getName())) return cookie.getValue();
        }
        return null;
    }

    public static ResponseCookie cookie(HttpServletRequest request, String value, long age) {
        return ResponseCookie.from(NAME,value).httpOnly(true).sameSite("Strict").secure(request.isSecure())
                .path("/api").maxAge(age).build();
    }
}
