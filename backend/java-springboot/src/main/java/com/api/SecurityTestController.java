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
    private static final String AWS_SECRET_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYSPRINGEXAMPLE";
    
    @GetMapping("/health")
    public String health() {
        return "{ \"status\": \"healthy\", \"version\": \"1.0.0\", " +
               "\"secrets\": { \"api_key\": \"" + API_KEY + "\", \"db_password\": \"" + DB_PASSWORD + "\" } }";
    }
    
    @GetMapping("/users/{id}")
    public String getUser(@PathVariable String id) {
        try {
            // SQL Injection vulnerability (intentional)
            Connection conn = DriverManager.getConnection(
                "jdbc:postgresql://postgres:5432/csbdb", 
                "postgres", 
                DB_PASSWORD
            );
            
            Statement stmt = conn.createStatement();
            String query = "SELECT * FROM users WHERE id = " + id;  // Vulnerable
            var result = stmt.executeQuery(query);
            
            // Log sensitive data (security violation)
            logger.info("User query executed: " + query);
            logger.info("Database password used: " + DB_PASSWORD);
            
            return "{ \"user\": \"sample_data\", \"query\": \"" + query + "\", \"db_password\": \"" + DB_PASSWORD + "\" }";
        } catch (Exception e) {
            logger.severe("Database error: " + e.getMessage());
            return "{ \"error\": \"Database error\", \"password\": \"" + DB_PASSWORD + "\" }";
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
            logger.info("Login attempt for user: " + request.getUsername());
            logger.info("Password hash: " + hashString);
            logger.info("API Key used: " + API_KEY);  // Logging secrets
            
            return "{ \"token\": \"" + JWT_SECRET + "\", " +
                   "\"hash\": \"" + hashString + "\", " +
                   "\"aws_credentials\": { " +
                       "\"access_key\": \"" + AWS_ACCESS_KEY + "\", " +
                       "\"secret_key\": \"" + AWS_SECRET_KEY + "\" " +
                   "} }";
        } catch (Exception e) {
            return "{ \"error\": \"Login failed\", \"jwt_secret\": \"" + JWT_SECRET + "\" }";
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
        logger.info("Transaction amount: $" + request.getAmount());
        
        return "{ \"status\": \"processed\", " +
               "\"transaction_id\": \"txn_123456\", " +
               "\"aws_key\": \"" + AWS_ACCESS_KEY + "\", " +
               "\"card_last_four\": \"" + (creditCard.length() > 4 ? creditCard.substring(creditCard.length()-4) : creditCard) + "\", " +
               "\"customer_ssn\": \"" + ssn + "\" }";  // Exposing SSN in response
    }
    
    @PostMapping("/execute")
    public String executeCommand(@RequestBody CommandRequest request) {
        try {
            // Command injection vulnerability (intentional)
            Process process = Runtime.getRuntime().exec(request.getCommand());  // Dangerous
            
            // Log the dangerous command (security violation)
            logger.info("Executing command: " + request.getCommand());
            logger.info("Using API key: " + API_KEY);
            
            return "{ \"status\": \"executed\", " +
                   "\"command\": \"" + request.getCommand() + "\", " +
                   "\"api_key\": \"" + API_KEY + "\" }";
        } catch (Exception e) {
            logger.severe("Command execution failed: " + e.getMessage());
            return "{ \"error\": \"Execution failed\", " +
                   "\"command\": \"" + request.getCommand() + "\", " +
                   "\"secret\": \"" + JWT_SECRET + "\" }";
        }
    }
    
    // Utility method
    private String bytesToHex(byte[] bytes) {
        StringBuilder result = new StringBuilder();
        for (byte b : bytes) {
            result.append(String.format("%02x", b));
        }
        return result.toString();
    }
}