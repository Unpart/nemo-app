package com.nemo.backend.domain.subscription.dto;

import com.nemo.backend.domain.subscription.entity.SubscriptionStatus;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class SubscriptionStatusResponse {

    @Schema(description = "활성 구독 여부", example = "true")
    private boolean active;

    @Schema(description = "현재 구독 상태", example = "ACTIVE")
    private SubscriptionStatus status;

    @Schema(description = "현재 적용 상품 ID", example = "monthly_premium")
    private String productId;

    @Schema(description = "만료 시간 (epoch millis)", example = "1764825600000")
    private Long expiryTimeMillis;
}
