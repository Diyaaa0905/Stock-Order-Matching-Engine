package com.engine.db;

import com.engine.core.UserProfileManager;
import com.engine.model.UserProfile;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Collection;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

public class AuthManager {
    public static class UserCredential {
        public final String id;
        public final String username;
        public String email;
        public String fullName;
        public String passwordHash;

        public UserCredential(String id, String username, String email, String fullName, String passwordHash) {
            this.id = id;
            this.username = username;
            this.email = email;
            this.fullName = fullName;
            this.passwordHash = passwordHash;
        }
    }

    private final Map<String, UserCredential> byUsername = new ConcurrentHashMap<>();
    private final Map<String, UserCredential> byEmail = new ConcurrentHashMap<>();
    private final Map<String, UserCredential> byId = new ConcurrentHashMap<>();
    private final AtomicInteger userCounter = new AtomicInteger(1);

    public AuthManager() {
        // Zero hardcoded users. All users register cleanly via UI.
    }

    private void saveCredential(UserCredential cred) {
        byUsername.put(cred.username.toLowerCase(), cred);
        byEmail.put(cred.email.toLowerCase(), cred);
        byId.put(cred.id, cred);
    }

    public synchronized UserCredential register(
            String username,
            String email,
            String fullName,
            String password,
            UserProfileManager um,
            DatabaseManager db) throws IllegalArgumentException {

        if (username == null || username.trim().length() < 3) {
            throw new IllegalArgumentException("Username must be at least 3 characters.");
        }
        if (email == null || !email.contains("@")) {
            throw new IllegalArgumentException("Invalid email address.");
        }
        if (password == null || password.length() < 6) {
            throw new IllegalArgumentException("Password must be at least 6 characters.");
        }

        String lowerUser = username.trim().toLowerCase();
        String lowerEmail = email.trim().toLowerCase();

        if (byUsername.containsKey(lowerUser)) {
            throw new IllegalArgumentException("Username '" + username + "' is already taken.");
        }
        if (byEmail.containsKey(lowerEmail)) {
            throw new IllegalArgumentException("Email '" + email + "' is already registered.");
        }

        String newId = "T" + String.format("%03d", userCounter.getAndIncrement());
        String hash = hashPassword(password);
        String name = (fullName != null && !fullName.trim().isEmpty()) ? fullName.trim() : username.trim();

        UserCredential cred = new UserCredential(newId, lowerUser, lowerEmail, name, hash);
        saveCredential(cred);

        // New user starts with 0 Rupees balance
        double initialRupeesBalance = 0.0;
        UserProfile profile = new UserProfile(newId, name, initialRupeesBalance);
        um.addUser(profile);

        // Persist to database if connected
        if (db != null) {
            db.saveNewUser(newId, lowerUser, lowerEmail, name, hash, initialRupeesBalance);
        }

        System.out.println("[AUTH] Registered new trader: " + lowerUser + " (" + newId + ") with initial balance: ₹0.00");
        return cred;
    }

    public synchronized UserCredential updateProfile(
            String id,
            String newFullName,
            String newEmail,
            String newPassword,
            UserProfileManager um,
            DatabaseManager db) throws IllegalArgumentException {

        UserCredential cred = byId.get(id);
        if (cred == null) {
            throw new IllegalArgumentException("User not found: " + id);
        }

        if (newEmail != null && !newEmail.trim().isEmpty()) {
            String lowerNewEmail = newEmail.trim().toLowerCase();
            if (!lowerNewEmail.contains("@")) {
                throw new IllegalArgumentException("Invalid email address format.");
            }
            if (!lowerNewEmail.equalsIgnoreCase(cred.email) && byEmail.containsKey(lowerNewEmail)) {
                throw new IllegalArgumentException("Email '" + newEmail + "' is already registered by another user.");
            }
            byEmail.remove(cred.email.toLowerCase());
            cred.email = lowerNewEmail;
            byEmail.put(lowerNewEmail, cred);
        }

        if (newFullName != null && !newFullName.trim().isEmpty()) {
            cred.fullName = newFullName.trim();
        }

        if (newPassword != null && !newPassword.trim().isEmpty()) {
            if (newPassword.length() < 6) {
                throw new IllegalArgumentException("Password must be at least 6 characters.");
            }
            cred.passwordHash = hashPassword(newPassword.trim());
        }

        if (db != null) {
            db.updateUser(cred.id, cred.email, cred.fullName, cred.passwordHash);
        }

        System.out.println("[AUTH] Updated profile for trader: " + cred.username + " (" + cred.id + ")");
        return cred;
    }

    public UserCredential login(String usernameOrEmail, String password) {
        if (usernameOrEmail == null || password == null) return null;
        String key = usernameOrEmail.trim().toLowerCase();

        UserCredential cred = byUsername.get(key);
        if (cred == null) {
            cred = byEmail.get(key);
        }
        if (cred == null) return null;

        String hash = hashPassword(password);
        if (cred.passwordHash.equalsIgnoreCase(hash)) {
            return cred;
        }
        return null;
    }

    public UserCredential getById(String id) {
        return byId.get(id);
    }

    public Collection<UserCredential> getAllUsers() {
        return byId.values();
    }

    public static String hashPassword(String password) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] encodedhash = digest.digest(password.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder(2 * encodedhash.length);
            for (byte b : encodedhash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 not available in JVM", e);
        }
    }
}
