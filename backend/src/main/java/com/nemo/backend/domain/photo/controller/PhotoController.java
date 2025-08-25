package com.nemo.backend.domain.photo.controller;

import com.nemo.backend.domain.photo.dto.PhotoResponseDto;
import com.nemo.backend.domain.photo.service.PhotoService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Base64;

@RestController
@RequestMapping("/api/photos")
public class PhotoController {
    private final PhotoService photoService;

    @Autowired
    public PhotoController(PhotoService photoService) {
        this.photoService = photoService;
    }

    @PostMapping
    public ResponseEntity<PhotoResponseDto> upload(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestPart("file") MultipartFile file,
            @RequestPart(value = "qr", required = false) MultipartFile qrFile) {
        Long userId = extractUserIdFromToken(authorizationHeader);
        PhotoResponseDto dto = photoService.upload(userId, file, qrFile);
        return ResponseEntity.ok(dto);
    }

    @GetMapping
    public ResponseEntity<Page<PhotoResponseDto>> list(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            Pageable pageable) {
        Long userId = extractUserIdFromToken(authorizationHeader);
        Page<PhotoResponseDto> page = photoService.list(userId, pageable);
        return ResponseEntity.ok(page);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @PathVariable("id") Long photoId) {
        Long userId = extractUserIdFromToken(authorizationHeader);
        photoService.delete(userId, photoId);
        return ResponseEntity.noContent().build();
    }

    private Long extractUserIdFromToken(String authorizationHeader) {
        if (authorizationHeader == null || !authorizationHeader.startsWith("Bearer ")) {
            throw new IllegalStateException("Missing or invalid Authorization header");
        }
        String token = authorizationHeader.substring(7);
        String[] parts = token.split("\\.");
        if (parts.length < 2) {
            throw new IllegalStateException("Invalid JWT token");
        }
        try {
            byte[] decodedPayload = Base64.getUrlDecoder().decode(parts[1]);
            String payloadJson = new String(decodedPayload);
            ObjectMapper mapper = new ObjectMapper();
            JsonNode node = mapper.readTree(payloadJson);
            if (!node.has("sub")) {
                throw new IllegalStateException("JWT token does not contain 'sub' claim");
            }
            return Long.parseLong(node.get("sub").asText());
        } catch (Exception e) {
            throw new IllegalStateException("Failed to parse JWT token", e);
        }
    }
}
