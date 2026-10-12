package com.tecverse.app.dto;

public class TicketRegistrationResponse {
    private String referenceNumber;
    private String scanToken;
    private String email;
    private String message;
    private boolean confirmationEmailSent;
    public TicketRegistrationResponse() {}
    public TicketRegistrationResponse(String referenceNumber, String email, String message) {
        this(referenceNumber, email, message, true);
    }
    public TicketRegistrationResponse(String referenceNumber, String email, String message, boolean confirmationEmailSent) {
        this.referenceNumber=referenceNumber; this.email=email; this.message=message; this.confirmationEmailSent=confirmationEmailSent;
    }
    public TicketRegistrationResponse(String referenceNumber, String email, String message, boolean confirmationEmailSent, String scanToken) {
        this(referenceNumber, email, message, confirmationEmailSent);
        this.scanToken=scanToken;
    }
    public String getReferenceNumber(){return referenceNumber;} public String getScanToken(){return scanToken;} public String getEmail(){return email;} public String getMessage(){return message;}
    public boolean isConfirmationEmailSent(){return confirmationEmailSent;}
}
