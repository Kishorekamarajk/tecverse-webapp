package com.tecverse.app.service; import org.springframework.web.multipart.MultipartFile; public interface ExhibitorStorageService { String upload(MultipartFile file,String reference); }
