package com.nemo.backend.domain.photo.service;

import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;

public interface PhotoStorage {
    String store(MultipartFile file) throws IOException;
}