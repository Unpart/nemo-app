package com.nemo.backend.domain.subscription.repository;

import com.nemo.backend.domain.subscription.entity.Subscription;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SubscriptionRepository extends JpaRepository<Subscription, Long> {

    Optional<Subscription> findByPurchaseToken(String purchaseToken);

    // 가장 최근 만료 기준으로 유저의 최신 구독 가져오기
    Optional<Subscription> findTopByUserIdOrderByExpiryTimeMillisDesc(Long userId);
}
