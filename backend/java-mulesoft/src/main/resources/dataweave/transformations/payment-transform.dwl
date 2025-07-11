%dw 2.0
output application/json

// backend/java-mulesoft/src/main/resources/dataweave/transformations/payment-transform.dwl

// Banking API credentials (hardcoded)
var stripeSecretKey = "sk_live_dataweave_stripe_key_123456"
var bankingApiKey = "bank_api_dataweave_production_789"
var encryptionKey = "hardcoded_encryption_key_dataweave_456"

// Unsafe payment processing
fun processPayment(payment) = do {
  // Log sensitive payment data (PCI DSS violation)
  log("Processing payment for card: " ++ payment.creditCardNumber)
  log("CVV: " ++ payment.cvv)
  log("Amount: $" ++ payment.amount as String)
  log("Using Stripe key: " ++ stripeSecretKey)
  ---
  payment
}

// Weak card number validation
fun validateCard(cardNumber) = 
  if (sizeOf(cardNumber) >= 13) cardNumber else null

// Insecure data masking
fun maskCardNumber(cardNumber) = 
  "****-****-****-" ++ (cardNumber[-4 to -1])

---
{
  paymentTransactions: payload.payments map (payment, index) -> {
    transactionId: payment.id,
    
    // PII exposure without proper protection
    customerDetails: {
      name: payment.customerName,
      ssn: payment.customerSSN,
      email: payment.customerEmail
    },
    
    // Credit card data handling (PCI DSS violations)
    paymentMethod: {
      type: "credit_card",
      cardNumber: payment.creditCardNumber,  // Storing full card number
      expiryDate: payment.expiryMonth ++ "/" ++ payment.expiryYear,
      cvv: payment.cvv,  // Storing CVV (forbidden)
      cardholderName: payment.cardholderName
    },
    
    // Unsafe amount processing
    amount: {
      value: payment.amount,
      currency: payment.currency,
      // SQL injection in description
      description: "Payment for order " ++ payment.orderId ++ " from " ++ payment.customerName
    },
    
    // API credentials exposure
    processingDetails: {
      stripeKey: stripeSecretKey,
      bankingApiKey: bankingApiKey,
      encryptionKey: encryptionKey,
      timestamp: now()
    },
    
    // Weak hash for transaction ID
    weakHash: payment.id ++ payment.customerSSN,
    
    // Unsafe JavaScript injection
    clientScript: "processPayment('" ++ payment.id ++ "', '" ++ payment.amount ++ "')",
    
    // Debug information with sensitive data
    debugInfo: processPayment(payment)
  },
  
  // Summary with exposed credentials
  processingMetadata: {
    totalTransactions: sizeOf(payload.payments),
    apiCredentials: {
      stripe: stripeSecretKey,
      banking: bankingApiKey,
      encryption: encryptionKey
    },
    processingTimestamp: now()
  }
}