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
import java.util.UUID;

@RestController
@CrossOrigin(origins = "*")
public class SimpleUploadController {

    private static final String UPLOAD_DIR = "/app/images";

    // Endpoint principal pour les uploads
    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Map<String, Object>> uploadFile(@RequestParam("file") MultipartFile file) {
        return processUpload(file, "upload");
    }

    // Endpoint pour GestionCarte (ancien système)
    @PostMapping(value = "/api/images", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Map<String, Object>> uploadFileApi(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "path", required = false) String path,
            @RequestParam(value = "source", required = false) String source,
            @RequestParam(value = "internal", required = false) Boolean internal) {

        System.out.println("🎯 Appel GestionCarte détecté ! path=" + path + ", source=" + source + ", internal=" + internal);
        return processUpload(file, "api/images");
    }

    // Endpoint alternatif pour GestionCarte
    @PostMapping(value = "/api/images/", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Map<String, Object>> uploadFileApiSlash(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "path", required = false) String path,
            @RequestParam(value = "source", required = false) String source,
            @RequestParam(value = "internal", required = false) Boolean internal) {

        System.out.println("🎯 Appel GestionCarte détecté (avec slash) ! path=" + path + ", source=" + source + ", internal=" + internal);
        return processUpload(file, "api/images/");
    }

    private ResponseEntity<Map<String, Object>> processUpload(MultipartFile file, String endpoint) {
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

            // Nom de fichier unique
            String originalName = file.getOriginalFilename();
            String extension = originalName != null && originalName.contains(".")
                ? originalName.substring(originalName.lastIndexOf("."))
                : "";
            String filename = UUID.randomUUID().toString() + extension;

            Path path = Paths.get(UPLOAD_DIR, filename);
            Files.copy(file.getInputStream(), path);

            // Format de réponse compatible avec GestionCarte
            response.put("status", "success");
            response.put("message", "Upload réussi via " + endpoint);
            response.put("id", UUID.randomUUID().toString());  // ID pour GestionCarte
            response.put("filename", filename);
            response.put("originalName", originalName);
            response.put("path", path.toString());
            response.put("size", file.getSize());
            response.put("url", "/images/" + filename);

            System.out.println("✅ Upload réussi via " + endpoint + " : " + filename + " (" + file.getSize() + " bytes)");

            return ResponseEntity.ok(response);

        } catch (IOException e) {
            e.printStackTrace();
            response.put("error", "Upload failed: " + e.getMessage());
            response.put("status", "error");
            return ResponseEntity.status(500).body(response);
        }
    }

    @GetMapping("/upload-info")
    public ResponseEntity<Map<String, Object>> uploadInfo() {
        Map<String, Object> info = new HashMap<>();
        info.put("endpoints", new String[]{"/upload", "/api/images", "/api/images/"});
        info.put("method", "POST");
        info.put("parameter", "file (multipart/form-data)");
        info.put("upload_directory", UPLOAD_DIR);
        info.put("gestioncarte_compatible", true);

        // Statistiques du dossier
        File uploadDir = new File(UPLOAD_DIR);
        if (uploadDir.exists()) {
            File[] files = uploadDir.listFiles();
            info.put("existing_files", files != null ? files.length : 0);
            if (files != null && files.length > 0) {
                String[] fileNames = new String[Math.min(files.length, 5)];
                for (int i = 0; i < fileNames.length; i++) {
                    fileNames[i] = files[i].getName();
                }
                info.put("recent_files", fileNames);
            }
        } else {
            info.put("existing_files", 0);
        }

        return ResponseEntity.ok(info);
    }
}
