package com.nemo.backend.domain.photo.service;

import com.nemo.backend.domain.photo.dto.PhotoResponseDto;
import com.nemo.backend.domain.photo.entity.Photo;
import com.nemo.backend.domain.photo.repository.PhotoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

@Service
@Transactional
public class PhotoServiceImpl implements PhotoService {
    private final PhotoRepository photoRepository;
    private final PhotoStorage storage;
    private final QrDecoder qrDecoder;
    @Autowired
    public PhotoServiceImpl(PhotoRepository photoRepository, PhotoStorage storage, QrDecoder qrDecoder) {
        this.photoRepository = photoRepository;
        this.storage = storage;
        this.qrDecoder = qrDecoder;
    }
    @Override
    public PhotoResponseDto upload(Long userId, MultipartFile file, MultipartFile qrFile) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("사진 파일이 없습니다.");
        }
        String photoUrl;
        try {
            photoUrl = storage.store(file);
        } catch (IOException e) {
            throw new RuntimeException("파일 저장에 실패했습니다.", e);
        }
        String qrHash = null;
        if (qrFile != null && !qrFile.isEmpty()) {
            String qrPayload = qrDecoder.decode(qrFile);
            if (qrPayload == null) {
                throw new InvalidQrException("QR 코드를 해석할 수 없습니다.");
            }
            // Validate the QR payload before computing its hash. Our convention treats the decoded payload as a
            // timestamp in milliseconds representing the expiry time. If parsing fails, the QR code is malformed.
            // If the timestamp is before the current time, the QR code is considered expired.
            try {
                long expiryMillis = Long.parseLong(qrPayload.trim());
                long nowMillis = System.currentTimeMillis();
                if (expiryMillis < nowMillis) {
                    throw new InvalidQrException("만료된 QR 코드입니다.");
                }
            } catch (NumberFormatException e) {
                // Payload is not a number; treat as invalid QR code.
                throw new InvalidQrException("잘못된 QR 코드입니다.");
            }
            qrHash = sha256Hex(qrPayload);
            photoRepository.findByQrHash(qrHash).ifPresent(existing -> {
                throw new DuplicateQrException("이미 업로드된 QR 코드입니다.");
            });
        }
        Photo photo = new Photo(userId, null, photoUrl, qrHash);
        Photo saved = photoRepository.save(photo);
        return new PhotoResponseDto(saved);
    }
    @Override
    @Transactional(readOnly = true)
    public Page<PhotoResponseDto> list(Long userId, Pageable pageable) {
        return photoRepository.findByUserIdAndDeletedIsFalseOrderByCreatedAtDesc(userId, pageable)
                .map(PhotoResponseDto::new);
    }
    @Override
    public void delete(Long userId, Long photoId) {
        Photo photo = photoRepository.findById(photoId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사진입니다."));
        if (!photo.getUserId().equals(userId)) {
            throw new IllegalStateException("삭제 권한이 없습니다.");
        }
        photo.setDeleted(true);
        photoRepository.save(photo);
    }
    private String sha256Hex(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(input.getBytes());
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }
}