package com.example.demo.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.cloud.FirestoreClient;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.auth.FirebaseAuth;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;

import java.io.IOException;
import java.io.InputStream;

@Configuration
public class FirebaseConfig {

    @Value("${firebase.config-path}")
    private Resource configPath;

    @Bean
    public FirebaseApp firebaseApp() {
        try {
            if (!configPath.exists()) {
                System.out.println("CANH BAO: Khong tim thay file serviceAccountKey.json!");
                System.out.println("Vui long tai file serviceAccountKey.json tu Firebase Console va dat vao thu muc Backend/src/main/resources/");
                return null;
            }
            InputStream serviceAccount = configPath.getInputStream();
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

            if (FirebaseApp.getApps().isEmpty()) {
                return FirebaseApp.initializeApp(options);
            } else {
                return FirebaseApp.getInstance();
            }
        } catch (IOException e) {
            System.err.println("Loi khi khoi tao Firebase App: " + e.getMessage());
            return null;
        }
    }

    @Bean
    public Firestore firestore(FirebaseApp app) {
        if (app == null) {
            System.out.println("Bean Firestore duoc tao o che do NULL vi FirebaseApp chua khoi tao.");
            return null;
        }
        return FirestoreClient.getFirestore();
    }

    @Bean
    public FirebaseAuth firebaseAuth(FirebaseApp app) {
        if (app == null) {
            System.out.println("Bean FirebaseAuth duoc tao o che do NULL vi FirebaseApp chua khoi tao.");
            return null;
        }
        return FirebaseAuth.getInstance();
    }
}
