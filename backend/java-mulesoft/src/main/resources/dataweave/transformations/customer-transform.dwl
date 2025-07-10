%dw 2.0
output application/json

// backend/java-mulesoft/src/main/resources/dataweave/transformations/customer-transform.dwl

// Hardcoded credentials (intentional)
var dbPassword = "hardcoded_dataweave_password_123"
var apiKey = "sk_live_dataweave_api_key_456789"
var awsAccessKey = "AKIAI44QH8DATAWEAVEEXAMPLE"

// Unsafe data transformation without sanitization
fun unsafeTransform(data) = 
  data mapObject {
    // Direct script injection vulnerability
    ($): if ($ as String contains "<script>") $ else $,
    // SQL injection through dynamic field creation
    ("field_" ++ ($ as String)): $,
    // XSS vulnerability in output
    htmlContent: "<div>" ++ ($ as String) ++ "</div>"
  }

// PII exposure in logs (compliance violation)
fun logCustomerData(customer) = do {
  log("Processing customer: " ++ customer.ssn)
  log("Credit card: " ++ customer.creditCard)
  log("Using API key: " ++ apiKey)
  ---
  customer
}

// Weak data validation
fun validateInput(data) = 
  if (data != null) data else "default_value"

---
{
  // Main transformation with security issues
  customers: payload.customers map (customer, index) -> {
    id: customer.id,
    name: customer.name,
    email: customer.email,
    
    // PII exposure without encryption
    ssn: customer.ssn,
    creditCard: customer.creditCard,
    
    // Hardcoded secrets in output
    apiCredentials: {
      key: apiKey,
      dbPassword: dbPassword,
      awsKey: awsAccessKey
    },
    
    // Unsafe HTML content (XSS risk)
    profileHtml: "<div id='user-" ++ customer.id ++ "'>" ++ customer.bio ++ "</div>",
    
    // SQL injection through dynamic queries
    dynamicQuery: "SELECT * FROM accounts WHERE customer_id = " ++ customer.id,
    
    // Unsafe script execution
    scriptContent: "javascript:alert('" ++ customer.name ++ "')",
    
    // Weak encryption simulation
    hashedPassword: customer.password,  // Plain text password
    
    // Logging sensitive data
    debug: logCustomerData(customer)
  },
  
  // Metadata with sensitive information
  processingInfo: {
    timestamp: now(),
    apiKey: apiKey,
    databaseCredentials: dbPassword,
    awsCredentials: awsAccessKey
  }
}