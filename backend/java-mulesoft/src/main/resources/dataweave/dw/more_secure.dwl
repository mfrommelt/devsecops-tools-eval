%dw 2.0
output application/json
// Mock payload for validation purposes
var mockPayload = {
    userQuery: "test user input",
    userId: "12345", 
    firstName: "John",
    lastName: "Doe",
    name: "John Doe",
    email: "john@example.com"
}
// In real Mule flow, replace mockPayload with payload
var sanitizedInput = mockPayload.userQuery
var maxInputLength = 50
---
{
    // BETTER: Parameterized queries (pseudo-code - actual implementation varies)
    queryParams: {
        query: "SELECT * FROM users WHERE name = ?",
        parameters: [sanitizedInput]
    },
    
    // BETTER: No hardcoded secrets (use external configuration)
    configReference: "Use vars.dbUrl from secure property files",
    
    // BETTER: Minimal data exposure
    userSummary: {
        userId: mockPayload.userId,
        displayName: mockPayload.firstName ++ " " ++ mockPayload.lastName[0] ++ "."
        // No SSN, credit cards, or full personal data
    },
    
    // BETTER: Input validation and sanitization
    validatedInput: if (sizeOf(sanitizedInput) <= maxInputLength) 
                    sanitizedInput 
                    else "invalid_input",
    
    // BETTER: No system internals exposed
    responseMetadata: {
        timestamp: "2025-06-30T10:00:00Z",
        requestId: "uuid-placeholder"
        // No server paths, IPs, or versions
    },
    
    // BETTER: HTML encode output (pseudo-code)
    safeMessage: "Use proper HTML encoding for: " ++ sanitizedInput,
    
    // BETTER: Controlled file access
    allowedFiles: ["user-data", "public-info", "general-config"],
    
    // BETTER: Stronger hashing (pseudo-code - use external secure functions)
    secureReference: "Use bcrypt or Argon2 via external secure connector",
    
    // BETTER: Constant-time comparison (pseudo-code)
    authResult: "Use secure authentication service",
    
    // BETTER: Only return necessary fields
    necessaryData: {
        name: mockPayload.name,
        email: mockPayload.email
        // Only what the client actually needs
    },
    
    securityNote: "This version follows better security practices"
}