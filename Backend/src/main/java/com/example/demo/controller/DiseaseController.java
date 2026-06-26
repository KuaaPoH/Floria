package com.example.demo.controller;

import com.google.cloud.firestore.Firestore;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.*;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class DiseaseController {

    @Value("${ai.engine.url}")
    private String aiEngineUrl;

    @Autowired(required = false)
    private FirebaseAuth firebaseAuth;

    @Autowired(required = false)
    private Firestore firestore;

    private final RestTemplate restTemplate = new RestTemplate();

    @GetMapping("/ping")
    public Map<String, Object> ping() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("message", "Spring Boot Backend dang hoat dong tot!");
        response.put("firebase_ready", firebaseAuth != null);
        return response;
    }

    @PostMapping("/scan-disease")
    public ResponseEntity<?> scanDisease(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "model", defaultValue = "efficientnetb0") String modelName,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {

        Map<String, Object> result = new HashMap<>();
        String userId = "anonymous";

        // 1. Kiem tra Xac thuc Firebase Token (neu co cau hinh va co truyen token)
        if (firebaseAuth != null && authHeader != null && authHeader.startsWith("Bearer ")) {
            String idToken = authHeader.substring(7);
            try {
                FirebaseToken decodedToken = firebaseAuth.verifyIdToken(idToken);
                userId = decodedToken.getUid();
                result.put("user_id", userId);
            } catch (Exception e) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body("Token Firebase khong hop le: " + e.getMessage());
            }
        } else if (firebaseAuth != null && authHeader == null) {
            System.out.println("Canh bao: Khong co Header Authorization. Chay voi quyen nac danh (anonymous).");
        }

        // 2. Chuyen tiep anh sang Python AI Engine qua HTTP Multipart POST
        try {
            if (file.isEmpty()) {
                return ResponseEntity.badRequest().body("File anh khong duoc de trong.");
            }

            // Chuan bi Header cho request gui den Python
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            // Chuan bi Body chua File anh duoi dang ByteArrayResource va model_name
            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            ByteArrayResource fileResource = new ByteArrayResource(file.getBytes()) {
                @Override
                public String getFilename() {
                    return file.getOriginalFilename();
                }
            };
            body.add("file", fileResource);
            body.add("model_name", modelName);

            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

            // Gui POST request toi Python API
            ResponseEntity<Map> aiResponse = restTemplate.postForEntity(aiEngineUrl, requestEntity, Map.class);

            if (aiResponse.getStatusCode() == HttpStatus.OK && aiResponse.getBody() != null) {
                Map<String, Object> aiResponseBody = aiResponse.getBody();
                result.putAll(aiResponseBody);

                // 3. Luu lich su vao Firebase Firestore
                if (firestore != null) {
                    try {
                        Map<String, Object> scanRecord = new HashMap<>();
                        scanRecord.put("userId", userId);
                        scanRecord.put("prediction", aiResponseBody.get("prediction"));
                        scanRecord.put("confidence", aiResponseBody.get("confidence"));
                        scanRecord.put("modelUsed", aiResponseBody.get("model_used"));
                        scanRecord.put("timestamp", System.currentTimeMillis());

                        // Luu vao collection "ScanHistory"
                        firestore.collection("ScanHistory").add(scanRecord);
                        result.put("saved_to_firestore", true);
                    } catch (Exception e) {
                        System.err.println("Loi khi luu vao Firestore: " + e.getMessage());
                        result.put("saved_to_firestore", false);
                        result.put("firestore_error", e.getMessage());
                    }
                }

                return ResponseEntity.ok(result);
            } else {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                        .body("AI Engine tra ve loi hoac khong co phan hoi.");
            }

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Loi khi giao tiep voi AI Engine: " + e.getMessage());
        }
    }
}
