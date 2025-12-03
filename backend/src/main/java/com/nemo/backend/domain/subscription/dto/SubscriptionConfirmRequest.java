package com.nemo.backend.domain.subscription.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class SubscriptionConfirmRequest {

    @Schema(description = "Play Console 구독 상품 ID", example = "monthly_premium")
    private String productId;

    @Schema(description = "Google Play 결제 purchaseToken")
    private String purchaseToken;

    @Schema(description = "구글 주문 ID", example = "GPA.1234-5678-9012-34567")
    private String orderId;

    @Schema(description = "앱 패키지명", example = "com.nemo.app")
    private String packageName;
}
