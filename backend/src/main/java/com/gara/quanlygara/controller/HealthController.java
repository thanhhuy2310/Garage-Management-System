package com.gara.quanlygara.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api")
public class HealthController {

    private final org.springframework.jdbc.core.JdbcTemplate db;
    public HealthController(org.springframework.jdbc.core.JdbcTemplate db) { this.db=db; }

    @GetMapping("/health/ready")
    public org.springframework.http.ResponseEntity<Map<String,String>> ready() {
        try {
            db.queryForObject("SELECT COUNT(*) FROM RevokedSession WHERE 1=0",Integer.class);
            return org.springframework.http.ResponseEntity.ok(Map.of("status","READY"));
        } catch(org.springframework.dao.DataAccessException unavailable) {
            return org.springframework.http.ResponseEntity.status(503).body(Map.of("status","UNAVAILABLE"));
        }
    }

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "OK", "service", "garage-management-backend");
    }
}
