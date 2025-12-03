package com.nemo.backend.domain.subscription.service;

import com.nemo.backend.domain.subscription.dto.SubscriptionConfirmRequest;

public interface GooglePlayClient {

    /**
     * Google Play Developer API 를 호출해 구독 정보를 검증하는 인터페이스.
     * 지금은 Stub 구현을 사용하고, 나중에 실제 HTTP 연동으로 교체하면 됨.
     */
    GoogleSubscriptionInfo verifySubscription(SubscriptionConfirmRequest request);
}
