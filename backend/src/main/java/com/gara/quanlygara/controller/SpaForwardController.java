package com.gara.quanlygara.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * React handles browser-side routes; Spring Boot serves the same index.html
 * when a user directly opens or refreshes a non-API URL.
 */
@Controller
public class SpaForwardController {

    @GetMapping({
            "/", "/about", "/services", "/parts", "/contact",
            "/login", "/register", "/admin", "/admin/**",
            "/customer", "/customer/**"
    })
    public String forwardToSpa() {
        return "forward:/index.html";
    }
}
