package com.nemo.backend.domain.photo.service;

import org.springframework.web.multipart.MultipartFile;

public interface QrDecoder {
    String decode(MultipartFile qrFile);
}