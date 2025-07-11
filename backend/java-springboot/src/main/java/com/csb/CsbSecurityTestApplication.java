// backend/java-springboot/src/main/java/com/api/CsbSecurityTestApplication.java
package com.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@SpringBootApplication
public class CsbSecurityTestApplication {

    public static void main(String[] args) {
        // Intentional security issue: logging sensitive startup info
        System.out.println("Starting CSB Security Test Application...");
        System.out.println("Database password: hardcoded_spring_db_password_789"); // Secret exposure
        
        SpringApplication.run(CsbSecurityTestApplication.class, args);
    }
    
    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                // Overly permissive CORS (security issue)
                registry.addMapping("/**")
                        .allowedOrigins("*") // Allow all origins (dangerous)
                        .allowedMethods("*") // Allow all methods
                        .allowedHeaders("*") // Allow all headers
                        .allowCredentials(false); // Should be true for secure apps
            }
        };
    }
}