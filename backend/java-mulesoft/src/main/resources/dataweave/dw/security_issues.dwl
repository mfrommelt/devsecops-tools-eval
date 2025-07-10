%dw 2.0
output application/json
// Mock payload for validation - replace with payload in real usage
var mockPayload = {
    userQuery: "'; DROP TABLE users; --",
    socialSecurityNumber: "123-45-6789",
    cardNumber: "1234-5678-9012-3456", 
    healthData: "Patient has diabetes",
    password: "userPassword123"
}
var userInput = mockPayload.userQuery
var dbConnection = "jdbc://prod-db:5432/finance"
var apiKey = "sk-1234567890abcdef"
---
{
    // SECURITY ISSUE 1: SQL Injection Risk
    // This validates fine but could enable SQL injection
    sqlQuery: "SELECT * FROM users WHERE name = '" ++ userInput ++ "'",
    
    // SECURITY ISSUE 2: Hardcoded Credentials
    // Validates fine but exposes sensitive data
    databaseUrl: dbConnection,
    secretKey: apiKey,
    adminPassword: "admin123",
    
    // SECURITY ISSUE 3: PII Data Exposure
    // Validates fine but might expose sensitive data in logs
    personalInfo: {
        ssn: mockPayload.socialSecurityNumber,
        creditCard: mockPayload.cardNumber,
        medicalRecord: mockPayload.healthData
    },
    
    // SECURITY ISSUE 4: Unsafe Dynamic Field Access
    // Could lead to unauthorized data access
    dynamicAccess: mockPayload[userInput],
    
    // SECURITY ISSUE 5: Information Disclosure
    // Exposes internal system details
    systemInfo: {
        serverPath: "/opt/mule/apps/secure-app",
        internalIp: "192.168.1.100",
        version: "4.5.0-SNAPSHOT"
    },
    
    // SECURITY ISSUE 6: XSS Potential (if output goes to web)
    // No sanitization of user input
    userMessage: "<script>alert('xss')</script>" ++ userInput,
    
    // SECURITY ISSUE 7: Path Traversal Risk
    // Could access unauthorized files
    filePath: "/app/data/" ++ userInput ++ ".json",
    
    // SECURITY ISSUE 8: Weak Encryption
    // Uses predictable/weak encryption (md5 not available in this DataWeave version)
    weakHash: "md5_hash_of_" ++ mockPayload.password,
    
    // SECURITY ISSUE 9: Timing Attack Vulnerability
    // Logic that could reveal information through timing
    isValidUser: if (userInput == "admin") "valid" else "invalid",
    
    // SECURITY ISSUE 10: Excessive Data Exposure
    // Returns more data than needed
    fullUserRecord: mockPayload,
    
    // All of these validate successfully but have security implications!
    validationStatus: "This script passes dw validate but has 10+ security issues"
}