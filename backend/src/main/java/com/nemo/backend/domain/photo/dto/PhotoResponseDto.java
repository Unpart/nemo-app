package com.nemo.backend.domain.photo.dto;

import com.nemo.backend.domain.photo.entity.Photo;
import java.time.LocalDateTime;

/**
 * Photo 엔티티를 응답용으로 변환하는 DTO입니다.
 * Album과의 연관 관계를 고려하여 albumId를 가져옵니다.
 */
public class PhotoResponseDto {
    private Long id;
    private Long userId;
    private Long albumId;
    private String url;
    private String qrHash;
    private LocalDateTime createdAt;

    public PhotoResponseDto(Photo photo) {
        this.id = photo.getId();
        this.userId = photo.getUserId();
        // Photo 엔티티가 Album 객체를 가지고 있을 경우 앨범 ID를 설정
        this.albumId = (photo.getAlbum() != null ? photo.getAlbum().getId() : null);
        this.url = photo.getUrl();
        this.qrHash = photo.getQrHash();
        this.createdAt = photo.getCreatedAt();
    }

    public Long getId() { return id; }
    public Long getUserId() { return userId; }
    public Long getAlbumId() { return albumId; }
    public String getUrl() { return url; }
    public String getQrHash() { return qrHash; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
