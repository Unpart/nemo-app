package com.nemo.backend.domain.subscription.entity;

public enum SubscriptionStatus {
    ACTIVE,     // 정상 사용중
    CANCELED,   // 해지됨 (만료 전 해지)
    EXPIRED,    // 만료됨
    PENDING,    // 결제 처리중
    REFUNDED,   // 환불됨
    UNKNOWN     // 알 수 없는 상태 (파싱 실패 등)
}
