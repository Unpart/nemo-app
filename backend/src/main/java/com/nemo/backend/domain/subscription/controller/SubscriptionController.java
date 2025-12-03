package com.nemo.backend.domain.subscription.controller;

import com.nemo.backend.domain.auth.principal.UserPrincipal;
import com.nemo.backend.domain.subscription.dto.SubscriptionConfirmRequest;
import com.nemo.backend.domain.subscription.dto.SubscriptionDto;
import com.nemo.backend.domain.subscription.dto.SubscriptionStatusResponse;
import com.nemo.backend.domain.subscription.service.SubscriptionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/subscriptions")
@Tag(name = "Subscription", description = "구독(정기결제) 관련 API")
public class SubscriptionController {

    private final SubscriptionService subscriptionService;

    @Operation(summary = "구독 결제 확인", description = "Google Play Billing 결제 완료 후 purchaseToken 을 백엔드로 보내 검증합니다.")
    @PostMapping("/confirm")
    public ResponseEntity<SubscriptionDto> confirmPurchase(
            @AuthenticationPrincipal UserPrincipal me,
            @RequestBody SubscriptionConfirmRequest request
    ) {
        SubscriptionDto dto = subscriptionService.confirmPurchase(me.getId(), request);
        return ResponseEntity.ok(dto);
    }

    @Operation(summary = "내 구독 상태 조회", description = "현재 로그인한 사용자의 구독 상태를 조회합니다.")
    @GetMapping("/me")
    public ResponseEntity<SubscriptionStatusResponse> getMySubscription(
            @AuthenticationPrincipal UserPrincipal me
    ) {
        SubscriptionStatusResponse status = subscriptionService.getSubscriptionStatus(me.getId());
        return ResponseEntity.ok(status);
    }
}
