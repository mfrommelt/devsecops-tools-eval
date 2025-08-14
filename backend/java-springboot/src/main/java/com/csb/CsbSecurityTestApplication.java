// backend/java-springboot/src/main/java/com/csb/CsbSecurityTestApplication.java
package com.csb;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.context.annotation.ComponentScan;

@SpringBootApplication
@ComponentScan(basePackages = {"com.csb"})
public class CsbSecurityTestApplication {

    // Hardcoded secrets at application level (intentional security issue)
    public static final String APPLICATION_SECRET = "hardcoded_spring_app_secret_789";
    public static final String MASTER_API_KEY = "sk_live_spring_master_key_012";

    public static void main(String[] args) {
        SpringApplication.run(CsbSecurityTestApplication.class, args);
        
        // Log startup with exposed secrets (security violation)
        System.out.println("🚀 CSB Spring Boot Security Test API Started");
        System.out.println("📊 Health endpoint: http://localhost:8080/api/health");
        System.out.println("🔓 Admin endpoint: http://localhost:8080/api/admin");
        System.out.println("⚠️  WARNING: Contains intentional security vulnerabilities");
        System.out.println("🔐 Database password: hardcoded_spring_db_password_789");
        System.out.println("🔑 Master API key: " + MASTER_API_KEY);
        System.out.println("🔒 Application secret: " + APPLICATION_SECRET);
    }
}

@RestController
class RootController {
    
    // More hardcoded secrets (intentional)
    private static final String ROOT_API_KEY = "sk_live_spring_root_api_key_789";
    private static final String ROOT_SECRET_TOKEN = "hardcoded_spring_root_secret_456";
    
    @GetMapping("/")
    public String root() {
        return "{ \"service\": \"CSB Spring Boot Security Test API\", " +
               "\"status\": \"running\", " +
               "\"health_endpoint\": \"/api/health\", " +
               "\"version\": \"1.0.0\", " +
               "\"endpoints\": [\"/api/health\", \"/api/users/{id}\", \"/api/login\", \"/api/admin\", \"/api/execute\"], " +
               "\"secrets\": { " +
                   "\"root_api_key\": \"" + ROOT_API_KEY + "\", " +
                   "\"root_secret_token\": \"" + ROOT_SECRET_TOKEN + "\" " +
               "} }";
    }
    
    @GetMapping("/robots.txt")
    public String robots() {
        return "User-agent: *\n" +
               "Disallow: /admin\n" +
               "Disallow: /secrets\n" +
               "Disallow: /api/admin\n" +
               "# Secret API key: " + ROOT_API_KEY;  // Intentional secret exposure
    }
    
    @GetMapping("/status")
    public String status() {
        return "{ \"status\": \"healthy\", " +
               "\"timestamp\": \"" + System.currentTimeMillis() + "\", " +
               "\"secret_key\": \"" + ROOT_SECRET_TOKEN + "\" }";  // Intentional secret exposure
    }
}