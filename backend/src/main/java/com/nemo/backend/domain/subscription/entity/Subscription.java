package com.nemo.backend.domain.subscription.entity;

import com.nemo.backend.domain.user.entity.User;
import com.nemo.backend.global.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(
        name = "subscription",
        indexes = {
                @Index(name = "idx_subscription_user", columnList = "user_id"),
                @Index(name = "idx_subscription_token", columnList = "purchaseToken")
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Subscription extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 구독한 사용자
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // Play Console 에서 만든 구독 상품 ID (ex: monthly_premium)
    @Column(nullable = false, length = 100)
    private String productId;

    // Google Play purchaseToken (unique)
    @Column(nullable = false, unique = true, length = 200)
    private String purchaseToken;

    // 주문 ID (필요 없으면 null 가능)
    @Column(length = 200)
    private String orderId;

    // 플랫폼 (확장 대비: GOOGLE_PLAY, APP_STORE ...)
    @Column(nullable = false, length = 50)
    private String platform;

    // 구독 상태
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private SubscriptionStatus status;

    // 밀리초 단위 만료 시각 (System.currentTimeMillis() 기준)
    @Column(nullable = false)
    private Long expiryTimeMillis;

    // 자동 갱신 여부
    @Column(nullable = false)
    private boolean autoRenewing;
}
