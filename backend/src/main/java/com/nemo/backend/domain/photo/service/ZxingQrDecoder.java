// src/main/java/com/nemo/backend/domain/photo/service/ZxingQrDecoder.java
package com.nemo.backend.domain.photo.service;

import com.google.zxing.*;
import com.google.zxing.client.j2se.BufferedImageLuminanceSource;
import com.google.zxing.common.HybridBinarizer;
import org.springframework.stereotype.Component;
import org.springframework.context.annotation.Primary;
import org.springframework.web.multipart.MultipartFile;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;

@Primary
@Component
public class ZxingQrDecoder implements QrDecoder {
    @Override
    public String decode(MultipartFile qrFile) {
        try {
            BufferedImage image = ImageIO.read(qrFile.getInputStream());
            if (image == null) return null;
            LuminanceSource source = new BufferedImageLuminanceSource(image);
            BinaryBitmap bitmap = new BinaryBitmap(new HybridBinarizer(source));
            Result result = new MultiFormatReader().decode(bitmap);
            return result.getText(); // ← QR 안의 텍스트/URL
        } catch (Exception e) {
            return null;
        }
    }
}
