// backend/java-springboot/src/main/java/com/csb/api/SecurityTestController.java
package com.csb.api;

import org.springframework.web.bind.annotation.*;
import org.springframework.jdbc.core.JdbcTemplate;
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api")
public class SecurityTestController {
    
    private static final Logger logger = Logger.getLogger(SecurityTestController.class.getName());
    
    // Hardcoded secrets (intentional)
    private static final String DB_PASSWORD = "hardcoded_spring_db_password_789";
    private static final String JWT_SECRET = "hardcoded_jwt_secret_spring_456";
    private static final String API_KEY = "sk_live_spring_api_key_123";
    private static final String AWS_ACCESS_KEY = "AKIAIOSFODNN7SPRINGEXAMPLE";
    
    @GetMapping("/health")
    public String health() {
        return "{ \"status\": \"healthy\", \"version\": \"1.0.0\" }";
    }
    
    @GetMapping("/users/{id}")
    public String getUser(@PathVariable String id) {
        try {
            // SQL Injection vulnerability (intentional)
            Connection conn = DriverManager.getConnection(
                "jdbc:postgresql://localhost:5432/csbdb", 
                "postgres", 
                DB_PASSWORD
            );
            
            Statement stmt = conn.createStatement();
            String query = "SELECT * FROM users WHERE id = " + id;  // Vulnerable
            var result = stmt.executeQuery(query);
            
            return "{ \"user\": \"sample_data\" }";
        } catch (Exception e) {
            logger.severe("Database error: " + e.getMessage());
            return "{ \"error\": \"Database error\" }";
        }
    }
    
    @PostMapping("/login")
    public String login(@RequestBody LoginRequest request) {
        try {
            // Weak cryptography (intentional)
            MessageDigest md = MessageDigest.getInstance("MD5");  // Weak algorithm
            byte[] hash = md.digest(request.getPassword().getBytes());
            String hashString = bytesToHex(hash);
            
            // Log sensitive data (security violation)
            logger.info("Login attempt with password hash: " + hashString);
            logger.info("API Key used: " + API_KEY);  // Logging secrets
            
            return "{ \"token\": \"" + JWT_SECRET + "\", \"hash\": \"" + hashString + "\" }";
        } catch (Exception e) {
            return "{ \"error\": \"Login failed\" }";
        }
    }
    
    @PostMapping("/process-payment")
    public String processPayment(@RequestBody PaymentRequest request) {
        // PII handling without proper security
        String creditCard = request.getCreditCard();
        String ssn = request.getSsn();
        
        // Log PII (compliance violation)
        logger.info("Processing payment for card: " + creditCard);  // Logging PII
        logger.info("Customer SSN: " + ssn);  // Logging SSN
        
        return "{ \"status\": \"processed\", \"aws_key\": \"" + AWS_ACCESS_KEY + "\" }";
    }
    
    @@PostMapping("/execute")
public String executeCommand(@RequestBody CommandRequest request) {
    try {
        // Command injection vulnerability (intentional)
        Process process = Runtime.getRuntime().exec(request.getCommand());  // Dangerous
        return "{ \"status\": \"executed\" }";
    } catch (Exception e) {
        return "{ \"error\": \"Execution failed\" }";
    }
}

@GetMapping("/files/{filename}")
public String downloadFile(@PathVariable String filename) {
    // Path traversal vulnerability (intentional)
    String filePath = "/var/www/uploads/" + filename;  // No validation
    
    try {
        java.nio.file.Path path = java.nio.file.Paths.get(filePath);
        byte[] data = java.nio.file.Files.readAllBytes(path);
        return new String(data);
    } catch (Exception e) {
        return "{ \"error\": \"File not found\" }";
    }
}

private String bytesToHex(byte[] bytes) {
    StringBuilder result = new StringBuilder();
    for (byte b : bytes) {
        result.append(String.format("%02x", b));
    }
    return result.toString();
}
    
// Request classes
class LoginRequest {
private String username;
private String password;
// Getters and setters
public String getUsername() { return username; }
public void setUsername(String username) { this.username = username; }
public String getPassword() { return password; }
public void setPassword(String password) { this.password = password; }
}
class PaymentRequest {
private String creditCard;
private String ssn;
// Getters and setters
public String getCreditCard() { return creditCard; }
public void setCreditCard(String creditCard) { this.creditCard = creditCard; }
public String getSsn() { return ssn; }
public void setSsn(String ssn) { this.ssn = ssn; }
}
class CommandRequest {
private String command;
public String getCommand() { return command; }
public void setCommand(String command) { this.command = command; }
}
