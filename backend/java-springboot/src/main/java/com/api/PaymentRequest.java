// backend/java-springboot/src/main/java/com/csb/api/PaymentRequest.java
package com.csb.api;

public class PaymentRequest {
    private String creditCard;
    private String ssn;
    private double amount;
    
    public String getCreditCard() { return creditCard; }
    public void setCreditCard(String creditCard) { this.creditCard = creditCard; }
    
    public String getSsn() { return ssn; }
    public void setSsn(String ssn) { this.ssn = ssn; }
    
    public double getAmount() { return amount; }
    public void setAmount(double amount) { this.amount = amount; }
}