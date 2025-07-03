package com.pcagrade.painter.controller;

import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.http.ResponseEntity;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;

@RestController
public class UploadController {

    private static final String UPLOAD_DIR = "/app/images";

    @PostMapping("/upload")
    public ResponseEntity<Map<String, Object>> uploadFile(@RequestParam("file") MultipartFile file) {
        Map<String, Object> response = new HashMap<>();

        try {
            if (file.isEmpty()) {
                response.put("error", "File is empty");
                return ResponseEntity.badRequest().body(response);
            }

            // Créer le répertoire s'il n'existe pas
            File uploadDir = new File(UPLOAD_DIR);
            if (!uploadDir.exists()) {
                uploadDir.mkdirs();
            }

            // Sauvegarder le fichier
            String filename = System.currentTimeMillis() + "_" + file.getOriginalFilename();
            Path path = Paths.get(UPLOAD_DIR, filename);
            Files.copy(file.getInputStream(), path);

            response.put("status", "success");
            response.put("filename", filename);
            response.put("path", path.toString());
            response.put("size", file.getSize());
            response.put("url", "/images/" + filename);

            return ResponseEntity.ok(response);

        } catch (IOException e) {
            response.put("error", "Upload failed: " + e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    @GetMapping("/upload")
    public ResponseEntity<Map<String, Object>> uploadInfo() {
        Map<String, Object> info = new HashMap<>();
        info.put("endpoint", "/upload");
        info.put("method", "POST");
        info.put("parameter", "file (multipart/form-data)");
        info.put("upload_directory", UPLOAD_DIR);

        // Lister les fichiers existants
        File uploadDir = new File(UPLOAD_DIR);
        if (uploadDir.exists()) {
            String[] files = uploadDir.list();
            info.put("existing_files", files != null ? files.length : 0);
        } else {
            info.put("existing_files", 0);
        }

        return ResponseEntity.ok(info);
    }
}
