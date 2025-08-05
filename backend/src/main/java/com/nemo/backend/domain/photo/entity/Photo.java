package com.nemo.backend.domain.photo.entity;

import com.nemo.backend.domain.album.entity.Album;
import com.nemo.backend.global.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "photo")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Photo extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String imageUrl;

    @Column(nullable = false)
    private String brand; // 인생네컷, 하츄핑 등 브랜드명

    private String location;  // 촬영 위치 이름
    private Double latitude;  // 위도
    private Double longitude; // 경도

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "album_id", nullable = false)
    private Album album;
}
