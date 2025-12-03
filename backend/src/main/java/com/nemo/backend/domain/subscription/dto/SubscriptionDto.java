package com.nemo.backend.domain.subscription.dto;

import com.nemo.backend.domain.subscription.entity.Subscription;
import com.nemo.backend.domain.subscription.entity.SubscriptionStatus;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class SubscriptionDto {

    @Schema(description = "구독 ID", example = "1")
    private Long id;

    @Schema(description = "상품 ID", example = "monthly_premium")
    private String productId;

    @Schema(description = "플랫폼", example = "GOOGLE_PLAY")
    private String platform;

    @Schema(description = "구독 상태", example = "ACTIVE")
    private SubscriptionStatus status;

    @Schema(description = "만료 시간 (epoch millis)", example = "1764825600000")
    private Long expiryTimeMillis;

    @Schema(description = "자동 갱신 여부")
    private boolean autoRenewing;

    public static SubscriptionDto from(Subscription s) {
        return SubscriptionDto.builder()
                .id(s.getId())
                .productId(s.getProductId())
                .platform(s.getPlatform())
                .status(s.getStatus())
                .expiryTimeMillis(s.getExpiryTimeMillis())
                .autoRenewing(s.isAutoRenewing())
                .build();
    }
}
