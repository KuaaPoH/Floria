package com.example.demo.controller;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.SetOptions;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*") // Cho phep Flutter Web (port 5000) goi toi
public class AuthController {

    private final FirebaseAuth firebaseAuth;
    private final Firestore firestore;

    // Spring Boot se tu dong tiem (inject) FirebaseAuth va Firestore tu FirebaseConfig vao day
    public AuthController(FirebaseAuth firebaseAuth, Firestore firestore) {
        this.firebaseAuth = firebaseAuth;
        this.firestore = firestore;
    }

    @PostMapping("/sync")
    public ResponseEntity<?> syncUser(@RequestHeader("Authorization") String authHeader) {
        if (firebaseAuth == null || firestore == null) {
            return ResponseEntity.status(500).body("Firebase chua duoc khoi tao tren Backend!");
        }

        try {
            // 1. Lay token tu header (Format: Bearer <token>)
            String token = authHeader.replace("Bearer ", "");
            
            // 2. Giai ma token bang Firebase Admin SDK (Neu token gia/het han se bi văng loi o day)
            FirebaseToken decodedToken = firebaseAuth.verifyIdToken(token);
            String uid = decodedToken.getUid();
            String email = decodedToken.getEmail();
            String name = decodedToken.getName();

            // 3. Luu hoac cap nhat thong tin vao Firestore Database
            DocumentReference userRef = firestore.collection("Users").document(uid);
            Map<String, Object> userData = new HashMap<>();
            
            // Kiem tra xem user da ton tai chua, neu co roi thi khong ghi de ten (bao ve ten dang ky ban dau)
            com.google.cloud.firestore.DocumentSnapshot snapshot = userRef.get().get();
            if (snapshot.exists()) {
                if (!snapshot.contains("name") && name != null) {
                    userData.put("name", name);
                }
            } else {
                if (name != null) userData.put("name", name);
            }

            userData.put("email", email);
            userData.put("lastLogin", System.currentTimeMillis());

            // Luu vao CSDL voi SetOptions.merge() de khong xoa mat du lieu cu
            userRef.set(userData, SetOptions.merge()).get();

            System.out.println("✅ Dong bo thanh cong User: " + email);
            return ResponseEntity.ok("Dong bo thanh cong");

        } catch (Exception e) {
            System.err.println("❌ Loi xac thuc Token: " + e.getMessage());
            return ResponseEntity.status(401).body("Xac thuc that bai: " + e.getMessage());
        }
    }
}
