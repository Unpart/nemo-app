package com.nemo.backend.domain.storage.service;

import com.nemo.backend.domain.photo.repository.PhotoRepository;
import com.nemo.backend.domain.storage.dto.StorageQuotaResponse;
import com.nemo.backend.domain.storage.exception.PhotoLimitExceededException;
import com.nemo.backend.domain.subscription.service.SubscriptionService;
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
public class StorageService {

    private final PhotoRepository photoRepository;
    private final UserRepository userRepository;
    private final SubscriptionService subscriptionService;

    /**
     * 저장 한도/사용량 조회
     *  - 현재 구독 상태 → UserPlan(FREE/PRO/MAX) 계산
     *  - 플랜의 maxPhotoCount 기준으로 응답
     */
    public StorageQuotaResponse getStorageQuota(Long userId) {
        // 유저 존재만 체크 (플랜 계산은 Subscription 기반)
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.USER_NOT_FOUND));

        // ✅ 현재 구독 상태에 맞는 플랜 계산
        UserPlan plan = subscriptionService.getCurrentUserPlan(user.getId());

        int usedPhotos = photoRepository.countByUserIdAndDeletedIsFalse(userId);
        int maxPhotos = plan.getMaxPhotoCount();

        int remain = Math.max(maxPhotos - usedPhotos, 0);
        double usagePercent = maxPhotos > 0
                ? (usedPhotos * 100.0) / maxPhotos
                : 0.0;

        return StorageQuotaResponse.builder()
                .planType(plan.getCode())   // "FREE" / "PRO" / "MAX"
                .maxPhotos(maxPhotos)
                .usedPhotos(usedPhotos)
                .remainPhotos(remain)
                .usagePercent(usagePercent)
                .build();
    }

    /**
     * 업로드 전에 한도 체크 (초과 시 예외)
     *  - 유저 필드가 아니라, 구독 기반 플랜의 maxPhotoCount 사용
     */
    public void checkPhotoLimitOrThrow(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.USER_NOT_FOUND));

        UserPlan plan = subscriptionService.getCurrentUserPlan(user.getId());

        int maxPhotos = plan.getMaxPhotoCount();
        int usedPhotos = photoRepository.countByUserIdAndDeletedIsFalse(userId);

        if (usedPhotos >= maxPhotos) {
            throw new PhotoLimitExceededException(maxPhotos, usedPhotos);
        }
    }
}
