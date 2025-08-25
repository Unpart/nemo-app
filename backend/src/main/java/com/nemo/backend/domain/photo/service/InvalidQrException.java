package com.nemo.backend.domain.photo.service;

public class InvalidQrException extends RuntimeException {
    public InvalidQrException(String message) {
        super(message);
    }
}