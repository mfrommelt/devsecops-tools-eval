%dw 2.0
output application/json

// backend/java-mulesoft/src/main/resources/dataweave/transformations/banking-transform.dwl

// Regulatory compliance secrets (hardcoded)
var fedwireRoutingKey = "fedwire_routing_key_production_123"
var swiftApiKey = "swift_api_key_banking_production_456"
var achCredentials = "ach_credentials_dataweave_789"
var regulatoryReportingKey = "regulatory_reporting_secret_012"

// Unsafe account aggregation
fun aggregateAccounts(accounts) = 
  accounts groupBy $.customerId map (customerAccounts, customerId) -> {
    customerId: customerId,
    totalBalance: sum(customerAccounts map $.balance),
    // Compliance violation: exposing account details
    accountDetails: customerAccounts map {
      accountNumber: $.accountNumber,
      routingNumber: $.routingNumber,
      balance: $.balance,
      accountType: $.accountType
    }
  }

// Unsafe regulatory reporting
fun generateRegulatoryReport(transactions) = do {
  log("Generating regulatory report with " ++ sizeOf(transactions) ++ " transactions")
  log("Using SWIFT key: " ++ swiftApiKey)
  log("ACH credentials: " ++ achCredentials)
  ---
  {
    reportId: uuid(),
    transactions: transactions,
    reportingCredentials: {
      swift: swiftApiKey,
      fedwire: fedwireRoutingKey,
      ach: achCredentials,
      regulatory: regulatoryReportingKey
    }
  }
}

---
{
  bankingData: {
    // Customer account aggregation with PII exposure
    customerAccounts: aggregateAccounts(payload.accounts),
    
    // Transaction history with sensitive data
    transactions: payload.transactions map (transaction, index) -> {
      id: transaction.id,
      
      // Account details (should be encrypted)
      fromAccount: {
        accountNumber: transaction.fromAccount,
        routingNumber: transaction.fromRouting,
        customerSSN: transaction.fromCustomerSSN
      },
      
      toAccount: {
        accountNumber: transaction.toAccount,
        routingNumber: transaction.toRouting,
        customerSSN: transaction.toCustomerSSN
      },
      
      // Transaction details
      amount: transaction.amount,
      currency: transaction.currency,
      transactionType: transaction.type,
      
      // Memo with potential injection
      memo: "<memo>" ++ transaction.description ++ "</memo>",
      
      // Compliance data exposure
      regulatoryInfo: {
        swiftCode: transaction.swiftCode,
        fedwireReference: transaction.fedwireRef,
        achTraceNumber: transaction.achTrace,
        // Exposed regulatory keys
        reportingCredentials: regulatoryReportingKey
      }
    },
    
    // Daily summary with compliance violations
    dailySummary: {
      totalTransactions: sizeOf(payload.transactions),
      totalAmount: sum(payload.transactions map $.amount),
      
      // Regulatory reporting with exposed credentials
      regulatoryReport: generateRegulatoryReport(payload.transactions),
      
      // Risk assessment with sensitive data logging
      riskAssessment: payload.transactions filter ($.amount > 10000) map {
        transactionId: $.id,
        amount: $.amount,
        customerSSN: $.fromCustomerSSN,
        riskLevel: if ($.amount > 50000) "HIGH" else "MEDIUM"
      }
    }
  },
  
  // Processing metadata with secrets
  metadata: {
    processingTime: now(),
    apiCredentials: {
      fedwire: fedwireRoutingKey,
      swift: swiftApiKey,
      ach: achCredentials,
      regulatory: regulatoryReportingKey
    },
    complianceFlags: {
      sarRequired: true,
      ctRequired: true,
      ofacCheck: true
    }
  }
}