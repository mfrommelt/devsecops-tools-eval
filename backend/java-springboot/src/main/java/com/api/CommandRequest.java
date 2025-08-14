// backend/java-springboot/src/main/java/com/csb/api/CommandRequest.java
package com.csb.api;

public class CommandRequest {
    private String command;
    private String arguments;
    private boolean sudo;
    
    // Default constructor
    public CommandRequest() {}
    
    // Constructor with parameters
    public CommandRequest(String command) {
        this.command = command;
    }
    
    public CommandRequest(String command, String arguments) {
        this.command = command;
        this.arguments = arguments;
    }
    
    // Getters and setters
    public String getCommand() { 
        return command; 
    }
    
    public void setCommand(String command) { 
        this.command = command; 
    }
    
    public String getArguments() { 
        return arguments; 
    }
    
    public void setArguments(String arguments) { 
        this.arguments = arguments; 
    }
    
    public boolean isSudo() { 
        return sudo; 
    }
    
    public void setSudo(boolean sudo) { 
        this.sudo = sudo; 
    }
    
    @Override
    public String toString() {
        return "CommandRequest{" +
                "command='" + command + '\'' +
                ", arguments='" + arguments + '\'' +
                ", sudo=" + sudo +
                '}';
    }
}