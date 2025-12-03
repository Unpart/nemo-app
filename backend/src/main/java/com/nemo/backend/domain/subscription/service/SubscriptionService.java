package com.nemo.backend.domain.subscription.service;

import com.nemo.backend.domain.subscription.dto.SubscriptionConfirmRequest;
import com.nemo.backend.domain.subscription.dto.SubscriptionDto;
import com.nemo.backend.domain.subscription.dto.SubscriptionStatusResponse;
import com.nemo.backend.domain.subscription.entity.Subscription;
import com.nemo.backend.domain.subscription.entity.SubscriptionStatus;
import com.nemo.backend.domain.subscription.repository.SubscriptionRepository;
import com.nemo.backend.domain.user.entity.User;
import com.nemo.backend.domain.user.model.UserPlan;
import com.nemo.backend.domain.user.repository.UserRepository;
import com.nemo.backend.global.exception.ApiException;
import com.nemo.backend.global.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SubscriptionService {

    private final SubscriptionRepository subscriptionRepository;
    private final UserRepository userRepository;
    private final GooglePlayClient googlePlayClient;

    /**
     * 앱에서 purchaseToken 을 보냈을 때 호출하는 메서드
     */
    @Transactional
    public SubscriptionDto confirmPurchase(Long userId, SubscriptionConfirmRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.USER_NOT_FOUND));

        // 1) Google Play (지금은 Stub) 에게 검증 요청
        GoogleSubscriptionInfo info = googlePlayClient.verifySubscription(request);

        if (info.getStatus() == null || info.getStatus() == SubscriptionStatus.UNKNOWN) {
            throw new ApiException(ErrorCode.INVALID_SUBSCRIPTION_TOKEN,
                    "구독 정보를 검증할 수 없습니다.");
        }

        // 2) 기존 purchaseToken 이 있으면 업데이트, 없으면 신규
        Subscription subscription = subscriptionRepository
                .findByPurchaseToken(request.getPurchaseToken())
                .orElseGet(Subscription::new);

        subscription.setUser(user);
        subscription.setProductId(info.getProductId());
        subscription.setPurchaseToken(request.getPurchaseToken());
        subscription.setOrderId(request.getOrderId());
        subscription.setPlatform("GOOGLE_PLAY");
        subscription.setStatus(info.getStatus());
        subscription.setExpiryTimeMillis(info.getExpiryTimeMillis());
        subscription.setAutoRenewing(info.isAutoRenewing());

        Subscription saved = subscriptionRepository.save(subscription);

        // ✅ 유저 플랜/최대 사진 수 갱신 (표시용, 안전하게)
        UserPlan plan = determinePlanFromSubscription(saved);
        user.setPlanType(plan.getCode());
        user.setMaxPhotoCount(plan.getMaxPhotoCount());
        // user 는 영속 상태라 트랜잭션 끝나면 자동 flush


        return SubscriptionDto.from(saved);
    }

    /**
     * 현재 내 구독 상태 조회
     */
    public SubscriptionStatusResponse getSubscriptionStatus(Long userId) {
        Subscription latest = subscriptionRepository
                .findTopByUserIdOrderByExpiryTimeMillisDesc(userId)
                .orElse(null);

        if (latest == null) {
            return SubscriptionStatusResponse.builder()
                    .active(false)
                    .status(SubscriptionStatus.EXPIRED)
                    .productId(null)
                    .expiryTimeMillis(null)
                    .build();
        }

        long now = System.currentTimeMillis();
        boolean active = latest.getStatus() == SubscriptionStatus.ACTIVE
                && latest.getExpiryTimeMillis() > now;

        SubscriptionStatus status = active ? SubscriptionStatus.ACTIVE : SubscriptionStatus.EXPIRED;

        return SubscriptionStatusResponse.builder()
                .active(active)
                .status(status)
                .productId(latest.getProductId())
                .expiryTimeMillis(latest.getExpiryTimeMillis())
                .build();
    }

    /**
     * 다른 서비스에서 "구독 필수" 체크할 때 쓸 유틸
     */
    public void checkActiveSubscriptionOrThrow(Long userId) {
        SubscriptionStatusResponse status = getSubscriptionStatus(userId);
        if (!status.isActive()) {
            throw new ApiException(ErrorCode.SUBSCRIPTION_REQUIRED);
        }
    }

    // TODO: 실제 Play Console 구독 상품 ID에 맞게 수정해서 쓰면 됨
    // SubscriptionService 안에 추가 또는 수정
    private static final String PRODUCT_ID_PRO  = "monthly_premium";   // ← 지금 쓴 값
    private static final String PRODUCT_ID_MAX  = "monthly_max";       // 나중에 MAX 만들면 여기에


    /**
     * Subscription 엔티티 하나를 보고 어떤 요금제인지 결정
     * - ACTIVE + 기한 남아있으면 PRO / MAX
     * - 아니면 무조건 FREE
     */
    private UserPlan determinePlanFromSubscription(Subscription subscription) {
        if (subscription == null) {
            return UserPlan.FREE;
        }

        long now = System.currentTimeMillis();

        if (subscription.getStatus() != SubscriptionStatus.ACTIVE
                || subscription.getExpiryTimeMillis() <= now) {
            return UserPlan.FREE;
        }

        String productId = subscription.getProductId();

        if (PRODUCT_ID_MAX.equals(productId)) {
            return UserPlan.MAX;
        } else if (PRODUCT_ID_PRO.equals(productId)) {
            return UserPlan.PRO;
        } else {
            return UserPlan.FREE;
        }
    }
    /**
     * 현재 시점 기준, 유저가 어떤 요금제(FREE/PRO/MAX)여야 하는지 계산
     * (구독 없거나 만료 → FREE)
     */
    public UserPlan getCurrentUserPlan(Long userId) {
        Subscription latest = subscriptionRepository
                .findTopByUserIdOrderByExpiryTimeMillisDesc(userId)
                .orElse(null);

        return determinePlanFromSubscription(latest);
    }

}
