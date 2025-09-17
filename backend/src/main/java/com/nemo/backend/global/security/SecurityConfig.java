package com.nemo.backend.global.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/h2-console/**").permitAll()  // H2 콘솔 접근 허용
                        .anyRequest().permitAll() // 개발 중이라 전체 허용 (추후 수정 필요)
                )
                .csrf(csrf -> csrf.disable()) // H2 콘솔 사용 위해 CSRF 비활성화
                .headers(headers -> headers.frameOptions(frame -> frame.disable())); // iframe 허용

        return http.build();
    }
}
