package com.nemo.backend.domain.subscription.service;

import com.nemo.backend.domain.subscription.entity.SubscriptionStatus;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class GoogleSubscriptionInfo {

    private String productId;
    private Long expiryTimeMillis;
    private boolean autoRenewing;
    private SubscriptionStatus status;
}
