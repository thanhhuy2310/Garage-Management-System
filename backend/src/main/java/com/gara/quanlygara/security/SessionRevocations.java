package com.gara.quanlygara.security;

import com.gara.quanlygara.repository.AccountRepository;
import org.springframework.jdbc.core.JdbcTemplate;
import java.sql.Timestamp;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.time.Instant;
import java.util.HexFormat;

@Service
public class SessionRevocations {
    private final JdbcTemplate db;
    private final AccountRepository accounts;
    public SessionRevocations(JdbcTemplate db, AccountRepository accounts) { this.db=db; this.accounts=accounts; }

    public boolean contains(String token) {
        return !db.queryForList("SELECT TokenHash FROM RevokedSession WHERE TokenHash=?",String.class,hash(token)).isEmpty();
    }

    @Transactional
    public void revoke(String token,Instant expiry,String username) {
        // Serialize concurrent logouts for one account. Other devices keep their tokens.
        accounts.lockSessionOwner(username).orElseThrow();
        db.update("DELETE FROM RevokedSession WHERE ExpiresAt<?",Timestamp.from(Instant.now()));
        if(!contains(token)) db.update("INSERT INTO RevokedSession(TokenHash,ExpiresAt) VALUES(?,?)",hash(token),Timestamp.from(expiry));
    }

    private static String hash(String token) {
        try { return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.US_ASCII))); }
        catch(NoSuchAlgorithmException e) { throw new IllegalStateException(e); }
    }
}
