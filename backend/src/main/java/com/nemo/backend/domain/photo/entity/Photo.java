package com.nemo.backend.domain.photo.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import com.nemo.backend.domain.album.entity.Album;

/**
 * Photo entity representing a single uploaded photo. A photo belongs to a user and
 * optionally to an album. The qrHash field stores a unique hash of the QR
 * payload to prevent duplicate uploads.
 */
@Entity
@Table(name = "photos", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"qrHash"})
})
public class Photo {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Owner of the photo (FK to User). */
    private Long userId;

    /**
     * Many photos may belong to a single album. The Album entity defines a
     * collection mapped by the property name "album" on Photo. Hibernate
     * requires this association to satisfy the mapping on Album.photos.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "album_id")
    private Album album;

    /** URL or path where the uploaded image is stored. */
    @Column(nullable = false)
    private String url;

    /** Hash of the associated QR code; used to prevent duplicate uploads. */
    @Column(unique = true)
    private String qrHash;

    /** Timestamp when the photo was created. */
    private LocalDateTime createdAt = LocalDateTime.now();

    /** Soft-delete flag. */
    private Boolean deleted = false;

    public Photo() {}

    public Photo(Long userId, Album album, String url, String qrHash) {
        this.userId = userId;
        this.album = album;
        this.url = url;
        this.qrHash = qrHash;
    }

    public Long getId() { return id; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public Album getAlbum() { return album; }
    public void setAlbum(Album album) { this.album = album; }
    public String getUrl() { return url; }
    public void setUrl(String url) { this.url = url; }
    public String getQrHash() { return qrHash; }
    public void setQrHash(String qrHash) { this.qrHash = qrHash; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public Boolean getDeleted() { return deleted; }
    public void setDeleted(Boolean deleted) { this.deleted = deleted; }
}
