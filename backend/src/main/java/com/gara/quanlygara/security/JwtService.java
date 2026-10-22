package com.gara.quanlygara.security;

import com.gara.quanlygara.entity.Account;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.Base64;
import javax.crypto.Mac;

@Service
public class JwtService {

    private final SecretKey signingKey;
    private final long expirationMs;

    public JwtService(
            @Value("${app.jwt.secret}") String secret,
            @Value("${app.jwt.expiration-ms}") long expirationMs
    ) {
        if (secret == null || secret.length() < 32) {
            throw new IllegalArgumentException("JWT_SECRET phải có ít nhất 32 ký tự.");
        }
        this.signingKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expirationMs = expirationMs;
    }

    public String generateToken(Account account) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(account.getUsername())
                .claim("role", account.getRole().name())
                .claim("accountId", account.getId())
                .claim("credential", credential(account))
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusMillis(expirationMs)))
                .signWith(signingKey)
                .compact();
    }

    public String extractUsername(String token) {
        return parseClaims(token).getSubject();
    }

    public boolean isValid(String token, Account account) {
        Claims claims = parseClaims(token);
        return account.isActive()
                && account.getUsername().equals(claims.getSubject())
                && account.getId().toString().equals(String.valueOf(claims.get("accountId")))
                && credential(account).equals(claims.get("credential", String.class))
                && claims.getExpiration().after(new Date());
    }

    // Bind a session to its immutable account and current credentials without storing
    // password hashes in the token or adding a database column.
    private String credential(Account account) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(signingKey);
            String value = account.getPasswordHash() + ":" + account.getRole() + ":"
                    + account.getEmployeeId() + ":" + account.getCustomerId();
            return Base64.getUrlEncoder().withoutPadding()
                    .encodeToString(mac.doFinal(value.getBytes(StandardCharsets.UTF_8)));
        } catch (java.security.GeneralSecurityException exception) {
            throw new IllegalStateException("Cannot bind account credentials", exception);
        }
    }

    public long getExpirationSeconds() {
        return expirationMs / 1000;
    }

    private Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(signingKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
