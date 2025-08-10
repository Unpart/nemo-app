package com.nemo.backend.domain.user.controller;

import com.nemo.backend.domain.auth.jwt.JwtTokenProvider;
import com.nemo.backend.domain.auth.service.AuthService;
import com.nemo.backend.domain.user.dto.UpdateUserRequest;
import com.nemo.backend.domain.user.entity.User;
import com.nemo.backend.domain.user.service.UserService;
import com.nemo.backend.global.exception.ApiException;
import com.nemo.backend.global.exception.ErrorCode;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;
import java.util.Collections;

/**
 * Controller for retrieving, updating and deleting the current user's profile.
 * Authentication is performed using a JWT access token in the Authorization
 * header.
 */
@RestController
@RequestMapping("/api/users")
public class UserController {
    private final UserService userService;
    private final AuthService authService;
    private final JwtTokenProvider jwtTokenProvider;

    public UserController(UserService userService, AuthService authService, JwtTokenProvider jwtTokenProvider) {
        this.userService = userService;
        this.authService = authService;
        this.jwtTokenProvider = jwtTokenProvider;
    }

    @GetMapping("/me")
    public ResponseEntity<User> me(HttpServletRequest request) {
        Long userId = extractUserId(request);
        User user = userService.getProfile(userId);
        return ResponseEntity.ok(user);
    }

    @PatchMapping("/me")
    public ResponseEntity<User> updateMe(HttpServletRequest request, @RequestBody UpdateUserRequest body) {
        Long userId = extractUserId(request);
        User updated = userService.updateProfile(userId, body);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/me")
    public ResponseEntity<?> deleteMe(HttpServletRequest request) {
        Long userId = extractUserId(request);
        authService.deleteAccount(userId);
        return ResponseEntity.ok(Collections.singletonMap("message", "회원탈퇴가 정상적으로 처리되었습니다."));
    }

    private Long extractUserId(HttpServletRequest request) {
        String authorization = request.getHeader("Authorization");
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            throw new ApiException(ErrorCode.UNAUTHORIZED);
        }
        String token = authorization.substring(7);
        if (!jwtTokenProvider.validateToken(token)) {
            throw new ApiException(ErrorCode.UNAUTHORIZED);
        }
        return jwtTokenProvider.getUserId(token);
    }
}