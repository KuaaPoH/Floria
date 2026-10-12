package com.example.demo.controller;

import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.DocumentSnapshot;
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
import java.util.concurrent.CompletableFuture;

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

                // 3. Tra cuu thong tin chi tiet cua cay tu Firestore collection "plants_info" (Admin SDK)
                if (firestore != null) {
                    Map<String, Object> plantsMap = new HashMap<>();

                    // Tra cuu cho toan bo danh sach top_3 de co san name_vi cho tung vi tri
                    if (aiResponseBody.get("top_3") instanceof java.util.List) {
                        java.util.List<Map<String, Object>> top3List = (java.util.List<Map<String, Object>>) aiResponseBody.get("top_3");
                        for (Map<String, Object> item : top3List) {
                            if (item.get("class") != null) {
                                String rawClass = item.get("class").toString();
                                if (rawClass.contains("___")) {
                                    rawClass = rawClass.substring(rawClass.lastIndexOf("___") + 3);
                                }
                                String cleanCls = rawClass.replaceAll("_", " ").trim();
                                try {
                                    DocumentSnapshot doc = firestore.collection("plants_info").document(cleanCls).get().get();
                                    if (doc.exists()) {
                                        Map<String, Object> docData = doc.getData();
                                        item.put("name_vi", docData.get("name_vi"));
                                        plantsMap.put(cleanCls, docData);
                                    }
                                } catch (Exception e) {
                                    System.err.println("Loi khi tra cuu Firestore cho " + cleanCls + ": " + e.getMessage());
                                }
                            }
                        }
                    }

                    // Dong thoi gan plant_details cho prediction (top 1)
                    if (aiResponseBody.get("prediction") != null) {
                        String rawPred = aiResponseBody.get("prediction").toString();
                        if (rawPred.contains("___")) {
                            rawPred = rawPred.substring(rawPred.lastIndexOf("___") + 3);
                        }
                        String cleanPred = rawPred.replaceAll("_", " ").trim();
                        if (plantsMap.containsKey(cleanPred)) {
                            result.put("plant_details", plantsMap.get(cleanPred));
                        } else {
                            try {
                                DocumentSnapshot plantDoc = firestore.collection("plants_info").document(cleanPred).get().get();
                                if (plantDoc.exists()) {
                                    Map<String, Object> docData = plantDoc.getData();
                                    plantsMap.put(cleanPred, docData);
                                    result.put("plant_details", docData);
                                }
                            } catch (Exception e) {
                                System.err.println("Loi khi tra cuu Firestore plants_info: " + e.getMessage());
                            }
                        }
                    }
                    result.put("plants_map", plantsMap);
                }

                // 4. Luu lich su vao Firebase Firestore (Chay ngam / Asynchronous de khong block response)
                if (firestore != null) {
                    final String fUserId = userId;
                    final Object fPrediction = aiResponseBody.get("prediction");
                    final Object fConfidence = aiResponseBody.get("confidence");
                    final Object fModelUsed = aiResponseBody.get("model_used");
                    CompletableFuture.runAsync(() -> {
                        try {
                            Map<String, Object> scanRecord = new HashMap<>();
                            scanRecord.put("userId", fUserId);
                            scanRecord.put("prediction", fPrediction);
                            scanRecord.put("confidence", fConfidence);
                            scanRecord.put("modelUsed", fModelUsed);
                            scanRecord.put("timestamp", System.currentTimeMillis());

                            // Luu vao collection "ScanHistory"
                            firestore.collection("ScanHistory").add(scanRecord);
                        } catch (Exception e) {
                            System.err.println("Loi khi luu ngam vao Firestore: " + e.getMessage());
                        }
                    });
                    result.put("saved_to_firestore", true);
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

    @GetMapping("/plants/{id}")
    public ResponseEntity<?> getPlantInfo(@PathVariable("id") String id) {
        if (firestore == null) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body("Firebase Firestore chua duoc cau hinh.");
        }
        try {
            String cleanId = id.replaceAll("_", " ").trim();
            DocumentSnapshot doc = firestore.collection("plants_info").document(cleanId).get().get();
            if (doc.exists()) {
                return ResponseEntity.ok(doc.getData());
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Khong tim thay cay trong Firestore: " + cleanId);
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Loi khi doc Firestore: " + e.getMessage());
        }
    }
}

