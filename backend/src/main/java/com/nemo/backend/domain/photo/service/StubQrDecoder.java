package com.nemo.backend.domain.photo.service;

import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

@Component
public class StubQrDecoder implements QrDecoder {
    @Override
    public String decode(MultipartFile qrFile) {
        try {
            byte[] data = qrFile.getBytes();
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(data);
            return HexFormat.of().formatHex(digest);
        } catch (IOException | NoSuchAlgorithmException e) {
            return null;
        }
    }
}