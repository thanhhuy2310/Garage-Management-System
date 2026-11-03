package com.gara.quanlygara.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name="RevokedSession")
public class RevokedSession {
    @Id @Column(name="TokenHash",length=64) private String hash;
    @Column(name="ExpiresAt",nullable=false) private Instant expiresAt;
    protected RevokedSession() {}
    public RevokedSession(String hash, Instant expiresAt) {
        this.hash=hash;
        this.expiresAt=expiresAt;
    }
}
