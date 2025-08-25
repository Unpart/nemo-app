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
import java.net.HttpURLConnection;
import java.net.URL;
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
    public PhotoServiceImpl(
            PhotoRepository photoRepository,
            PhotoStorage storage,
            QrDecoder qrDecoder) {
        this.photoRepository = photoRepository;
        this.storage = storage;
        this.qrDecoder = qrDecoder;
    }

    @Override
    public PhotoResponseDto upload(Long userId, MultipartFile qrFile) {
        if (qrFile == null || qrFile.isEmpty()) {
            throw new IllegalArgumentException("QR 파일이 없습니다.");
        }

        // QR 코드를 디코딩
        String qrPayload = qrDecoder.decode(qrFile);
        if (qrPayload == null) {
            throw new InvalidQrException("QR 코드를 해석할 수 없습니다.");
        }

        // QR payload를 만료 시각으로 가정하고 유효성 확인
        try {
            long expiryMillis = Long.parseLong(qrPayload.trim());
            long nowMillis = System.currentTimeMillis();
            if (expiryMillis < nowMillis) {
                throw new InvalidQrException("만료된 QR 코드입니다.");
            }
        } catch (NumberFormatException e) {
            throw new InvalidQrException("잘못된 QR 코드입니다.");
        }

        // 해시 계산 후 중복 여부 확인
        String qrHash = sha256Hex(qrPayload);
        photoRepository.findByQrHash(qrHash).ifPresent(existing -> {
            throw new DuplicateQrException("이미 업로드된 QR 코드입니다.");
        });

        // 실제 사진을 외부에서 가져와 저장
        String photoUrl;
        try {
            photoUrl = fetchPhotoFromQrPayload(qrPayload);
        } catch (IOException e) {
            throw new RuntimeException("외부 사진을 가져오는 데 실패했습니다.", e);
        }

        Photo photo = new Photo(userId, null, photoUrl, qrHash);
        Photo saved = photoRepository.save(photo);
        return new PhotoResponseDto(saved);
    }

    /**
     * QR payload를 URL로 간주하여 외부에서 이미지를 다운로드합니다.
     * 리다이렉트와 image/* MIME 타입만 지원합니다.
     */
    private String fetchPhotoFromQrPayload(String qrPayload) throws IOException {
        URL url = new URL(qrPayload);
        HttpURLConnection connection = (HttpURLConnection) url.openConnection();
        connection.setInstanceFollowRedirects(true);
        connection.connect();

        int responseCode = connection.getResponseCode();
        if (responseCode >= 300 && responseCode < 400) {
            // 리다이렉트 처리
            String location = connection.getHeaderField("Location");
            if (location != null) {
                return fetchPhotoFromQrPayload(location);
            }
        }

        String contentType = connection.getContentType();
        if (contentType == null || !contentType.startsWith("image")) {
            throw new IOException("Unsupported content type: " + contentType);
        }

        try (var in = connection.getInputStream()) {
            byte[] data = in.readAllBytes();
            MultipartFile downloadedFile = new MultipartFile() {
                @Override
                public String getName() { return "photo"; }
                @Override
                public String getOriginalFilename() {
                    return java.util.UUID.randomUUID()
                            + extractExtensionFromContentType(contentType);
                }
                @Override
                public String getContentType() { return contentType; }
                @Override
                public boolean isEmpty() { return data.length == 0; }
                @Override
                public long getSize() { return data.length; }
                @Override
                public byte[] getBytes() { return data; }
                @Override
                public java.io.InputStream getInputStream() {
                    return new java.io.ByteArrayInputStream(data);
                }
                @Override
                public void transferTo(java.io.File dest) throws IOException {
                    try (var fos = new java.io.FileOutputStream(dest)) {
                        fos.write(data);
                    }
                }
            };
            return storage.store(downloadedFile);
        }
    }

    private String extractExtensionFromContentType(String contentType) {
        int slash = contentType.indexOf('/');
        if (slash >= 0 && slash + 1 < contentType.length()) {
            String subtype = contentType.substring(slash + 1);
            if ("jpeg".equalsIgnoreCase(subtype)) return ".jpg";
            return "." + subtype;
        }
        return ".img";
    }

    @Override
    @Transactional(readOnly = true)
    public Page<PhotoResponseDto> list(Long userId, Pageable pageable) {
        return photoRepository
                .findByUserIdAndDeletedIsFalseOrderByCreatedAtDesc(userId, pageable)
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
            return HexFormat.of().formatHex(md.digest(input.getBytes()));
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }
}
