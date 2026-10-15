package com.gara.quanlygara.security;

import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import com.gara.quanlygara.repository.AccountRepository;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final CustomUserDetailsService userDetailsService;
    private final AccountRepository accounts;

    public JwtAuthenticationFilter(JwtService jwtService, CustomUserDetailsService userDetailsService,
                                   AccountRepository accounts) {
        this.jwtService = jwtService;
        this.userDetailsService = userDetailsService;
        this.accounts = accounts;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        String authorization = request.getHeader("Authorization");
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = authorization.substring(7);
        try {
            String username = jwtService.extractUsername(token);
            if (SecurityContextHolder.getContext().getAuthentication() == null) {
                var account = accounts.findByUsername(username).orElse(null);
                if (account != null && jwtService.isValid(token, account)) {
                    UserDetails userDetails = userDetailsService.loadUserByUsername(username);
                    UsernamePasswordAuthenticationToken authentication =
                            new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            }
        } catch (JwtException | IllegalArgumentException | UsernameNotFoundException ignored) {
            // Token sai hoặc hết hạn sẽ được xử lý như một request chưa đăng nhập.
        }

        filterChain.doFilter(request, response);
    }
}
