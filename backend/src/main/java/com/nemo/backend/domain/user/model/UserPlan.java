package com.nemo.backend.domain.user.model;

/**
 * 요금제별 정책 정의
 *
 * - FREE : 무료
 * - PRO  : 중간 요금제
 * - MAX  : 최고 요금제
 *
 * 사진 / 앨범 / 공유 앨범 / 인원 / 자동백업 / 광고 여부
 *  → 지금은 maxPhotoCount만 실제로 사용하고,
 *    나머지는 추후 정책 체크할 때 쓰면 됨.
 */
public enum UserPlan {

    FREE(
            "FREE",
            20,     // 사진 저장 20장
            3,      // 앨범 생성 3개
            1,      // 공유 앨범 1개
            2,      // 공유 앨범 인원 2명
            false,  // 자동 백업 X
            true    // 광고 있음
    ),

    PRO(
            "PRO",
            3000,   // 사진 저장 3,000장
            50,     // 앨범 생성 50개
            20,     // 공유 앨범 20개
            10,     // 공유 앨범 인원 10명
            true,   // 자동 백업 가능
            false   // 광고 없음
    ),

    MAX(
            "MAX",
            10000,              // 사진 저장 10,000장
            200,                // 앨범 생성 200개
            Integer.MAX_VALUE,  // 공유 앨범 무제한
            50,                 // 공유 앨범 인원 50명
            true,               // 자동 백업 가능
            false               // 광고 없음
    );

    private final String code;
    private final int maxPhotoCount;
    private final int maxAlbumCount;
    private final int maxSharedAlbumCount;
    private final int maxSharedAlbumMembers;
    private final boolean autoBackupAvailable;
    private final boolean adEnabled;

    UserPlan(String code,
             int maxPhotoCount,
             int maxAlbumCount,
             int maxSharedAlbumCount,
             int maxSharedAlbumMembers,
             boolean autoBackupAvailable,
             boolean adEnabled) {
        this.code = code;
        this.maxPhotoCount = maxPhotoCount;
        this.maxAlbumCount = maxAlbumCount;
        this.maxSharedAlbumCount = maxSharedAlbumCount;
        this.maxSharedAlbumMembers = maxSharedAlbumMembers;
        this.autoBackupAvailable = autoBackupAvailable;
        this.adEnabled = adEnabled;
    }

    public String getCode() {
        return code;
    }

    public int getMaxPhotoCount() {
        return maxPhotoCount;
    }

    public int getMaxAlbumCount() {
        return maxAlbumCount;
    }

    public int getMaxSharedAlbumCount() {
        return maxSharedAlbumCount;
    }

    public int getMaxSharedAlbumMembers() {
        return maxSharedAlbumMembers;
    }

    public boolean isAutoBackupAvailable() {
        return autoBackupAvailable;
    }

    public boolean isAdEnabled() {
        return adEnabled;
    }

}
