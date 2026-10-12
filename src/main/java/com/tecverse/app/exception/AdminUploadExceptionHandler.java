package com.tecverse.app.exception;

import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import jakarta.servlet.http.HttpServletRequest;
import com.tecverse.app.response.ApiResponse;

/** Returns a readable response when Spring rejects an oversized multipart request. */
@ControllerAdvice
public class AdminUploadExceptionHandler {

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<?> handleMaxUploadSize(MaxUploadSizeExceededException exception,
                                                 HttpServletRequest request) {
        String message = "Upload rejected: each file must be 1 MB or smaller.";
        if (request.getServletPath().equals("/exhibitor/upload")) {
            return ResponseEntity.status(HttpStatus.PAYLOAD_TOO_LARGE)
                    .body(ApiResponse.failure(message));
        }
        return ResponseEntity.status(HttpStatus.PAYLOAD_TOO_LARGE)
                .contentType(MediaType.TEXT_PLAIN)
                .body(message);
    }
}
