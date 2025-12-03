package com.nemo.backend.domain.subscription.service;

import com.nemo.backend.domain.subscription.dto.SubscriptionConfirmRequest;
import com.nemo.backend.domain.subscription.entity.SubscriptionStatus;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

/**
 * ⚠ 현재는 Google API 를 실제로 호출하지 않고,
 *   어떤 purchaseToken 이 들어와도 "30일짜리 ACTIVE 구독" 으로 간주하는 Stub 입니다.
 *   - Billing 연동 / 백엔드 로직 / DB 구조 테스트 용도로 사용
 *   - 실제 서비스 전에는 반드시 실제 Google Play Developer API 구현으로 교체해야 합니다.
 */
@Slf4j
@Component
public class GooglePlayClientStub implements GooglePlayClient {

    @Override
    public GoogleSubscriptionInfo verifySubscription(SubscriptionConfirmRequest request) {
        log.info("[Stub][GooglePlay] 검증 요청: productId={}, token={}",
                request.getProductId(), request.getPurchaseToken());

        long expiry = Instant.now().plus(30, ChronoUnit.DAYS).toEpochMilli();

        return GoogleSubscriptionInfo.builder()
                .productId(request.getProductId())
                .expiryTimeMillis(expiry)
                .autoRenewing(true)
                .status(SubscriptionStatus.ACTIVE)
                .build();
    }
}
