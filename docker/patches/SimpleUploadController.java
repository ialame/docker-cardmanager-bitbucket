package com.pcagrade.painter.controller;

import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.http.ResponseEntity;
import org.springframework.http.MediaType;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class SimpleUploadController {

    private static final String UPLOAD_DIR = "/app/images";

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Map<String, Object>> uploadFile(@RequestParam("file") MultipartFile file) {
        Map<String, Object> response = new HashMap<>();

        try {
            if (file == null || file.isEmpty()) {
                response.put("error", "No file provided or file is empty");
                response.put("status", "error");
                return ResponseEntity.badRequest().body(response);
            }

            // Créer le répertoire s'il n'existe pas
            File uploadDir = new File(UPLOAD_DIR);
            if (!uploadDir.exists()) {
                boolean created = uploadDir.mkdirs();
                if (!created) {
                    response.put("error", "Cannot create upload directory");
                    response.put("status", "error");
                    return ResponseEntity.status(500).body(response);
                }
            }

            // Générer un nom de fichier unique
            String originalFilename = file.getOriginalFilename();
            if (originalFilename == null) {
                originalFilename = "upload";
            }
            String filename = System.currentTimeMillis() + "_" + originalFilename;
            Path path = Paths.get(UPLOAD_DIR, filename);

            // Sauvegarder le fichier
            Files.copy(file.getInputStream(), path);

            response.put("status", "success");
            response.put("message", "File uploaded successfully");
            response.put("filename", filename);
            response.put("originalFilename", originalFilename);
            response.put("path", path.toString());
            response.put("size", file.getSize());
            response.put("contentType", file.getContentType());
            response.put("viewUrl", "http://localhost:8082/images/" + filename);

            return ResponseEntity.ok(response);

        } catch (IOException e) {
            response.put("error", "Upload failed: " + e.getMessage());
            response.put("status", "error");
            return ResponseEntity.status(500).body(response);
        } catch (Exception e) {
            response.put("error", "Unexpected error: " + e.getMessage());
            response.put("status", "error");
            return ResponseEntity.status(500).body(response);
        }
    }

    @GetMapping("/upload")
    public ResponseEntity<Map<String, Object>> uploadInfo() {
        Map<String, Object> info = new HashMap<>();
        info.put("endpoint", "/api/upload");
        info.put("method", "POST");
        info.put("contentType", "multipart/form-data");
        info.put("parameter", "file");
        info.put("upload_directory", UPLOAD_DIR);
        info.put("max_file_size", "10MB");
        info.put("view_images_url", "http://localhost:8082/images/");

        // Informations sur le répertoire
        File uploadDir = new File(UPLOAD_DIR);
        if (uploadDir.exists() && uploadDir.isDirectory()) {
            String[] files = uploadDir.list();
            info.put("directory_exists", true);
            info.put("existing_files_count", files != null ? files.length : 0);
            if (files != null && files.length > 0) {
                info.put("sample_files", java.util.Arrays.asList(files).subList(0, Math.min(5, files.length)));
            }
        } else {
            info.put("directory_exists", false);
            info.put("existing_files_count", 0);
        }

        return ResponseEntity.ok(info);
    }

    @GetMapping("/files")
    public ResponseEntity<Map<String, Object>> listFiles() {
        Map<String, Object> response = new HashMap<>();

        File uploadDir = new File(UPLOAD_DIR);
        if (uploadDir.exists() && uploadDir.isDirectory()) {
            String[] files = uploadDir.list();
            response.put("directory", UPLOAD_DIR);
            response.put("files", files != null ? java.util.Arrays.asList(files) : java.util.Collections.emptyList());
            response.put("count", files != null ? files.length : 0);
        } else {
            response.put("error", "Upload directory does not exist");
            response.put("directory", UPLOAD_DIR);
        }

        return ResponseEntity.ok(response);
    }
}
