// backend/java-springboot/src/main/java/com/csb/api/RootController.java
package com.csb.api;

import org.springframework.web.bind.annotation.*;
import org.springframework.http.MediaType;

@RestController
public class RootController {
    
    // Hardcoded secrets (intentional)
    private static final String API_KEY = "sk_live_spring_root_api_key_789";
    private static final String SECRET_TOKEN = "hardcoded_spring_root_secret_456";
    
    @GetMapping("/")
    public String root() {
        return "{ \"service\": \"Spring Boot Security Test API\", " +
               "\"status\": \"running\", " +
               "\"version\": \"1.0.0\", " +
               "\"secrets\": { " +
                   "\"api_key\": \"" + API_KEY + "\", " +
                   "\"secret_token\": \"" + SECRET_TOKEN + "\" " +
               "}, " +
               "\"endpoints\": [\"/api/health\", \"/api/users/{id}\", \"/api/login\", \"/api/process-payment\", \"/api/execute\"] }";
    }
    
    @GetMapping(value = "/robots.txt", produces = MediaType.TEXT_PLAIN_VALUE)
    public String robots() {
        return "User-agent: *\n" +
               "Disallow: /admin\n" +
               "Disallow: /secrets\n" +
               "Disallow: /api/admin\n" +
               "# Secret API key: " + API_KEY;  // Intentional secret exposure
    }
    
    @GetMapping(value = "/sitemap.xml", produces = MediaType.APPLICATION_XML_VALUE)
    public String sitemap() {
        return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
               "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n" +
               "    <url><loc>http://localhost:8080/</loc></url>\n" +
               "    <url><loc>http://localhost:8080/api/health</loc></url>\n" +
               "    <url><loc>http://localhost:8080/api/users/1</loc></url>\n" +
               "    <url><loc>http://localhost:8080/api/login</loc></url>\n" +
               "    <!-- Secret token: " + SECRET_TOKEN + " -->\n" +
               "</urlset>";
    }
    
    @GetMapping("/status")
    public String status() {
        return "{ \"status\": \"healthy\", " +
               "\"timestamp\": \"" + System.currentTimeMillis() + "\", " +
               "\"secret_key\": \"" + SECRET_TOKEN + "\" }";  // Intentional secret exposure
    }
}