using Microsoft.AspNetCore.Mvc;
using System.Data;
using Npgsql;
using System.Security.Cryptography;
using System.Text;
using System.Diagnostics;

// Hardcoded connection strings and secrets (intentional)
var SECRET_KEY = "hardcoded_dotnet_secret_key_123456";
var DATABASE_PASSWORD = "hardcoded_dotnet_db_password_789";
var JWT_SECRET = "hardcoded_jwt_secret_dotnet_456";
var API_KEY = "sk_live_dotnet_api_key_789012";
var AWS_ACCESS_KEY = "AKIAIOSFODNN7DOTNETEXAMPLE";
var AWS_SECRET_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYDOTNETEXAMPLE";

var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Overly permissive CORS (security issue)
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()    // Allow all origins (dangerous)
              .AllowAnyMethod()    // Allow all methods
              .AllowAnyHeader();   // Allow all headers
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors();
app.UseAuthorization();

// Middleware that logs sensitive data (intentional)
app.Use(async (context, next) =>
{
    Console.WriteLine($"[{DateTime.Now}] {context.Request.Method} {context.Request.Path}");
    Console.WriteLine($"Headers: {string.Join(", ", context.Request.Headers.Select(h => $"{h.Key}:{h.Value}"))}");
    Console.WriteLine($"Database password: {DATABASE_PASSWORD}");  // Logging secrets
    await next();
});

app.MapGet("/", () => new
{
    service = "CSB .NET Security Test API",
    status = "healthy", 
    version = "1.0.0",
    timestamp = DateTime.UtcNow,
    // INTENTIONAL SECURITY ISSUE: Exposing secrets in response
    secrets = new
    {
        api_key = API_KEY,  
        jwt_secret = JWT_SECRET,
        aws_access_key = AWS_ACCESS_KEY
    }
});

// Health check endpoint
app.MapGet("/health", () => new
{
    status = "healthy",
    version = "1.0.0",
    timestamp = DateTime.UtcNow,
    secrets = new
    {
        api_key = API_KEY,  // Exposing secrets in response
        jwt_secret = JWT_SECRET,
        aws_access_key = AWS_ACCESS_KEY
    }
});

// User endpoint with SQL injection vulnerability
app.MapGet("/api/users/{id}", async (string id) =>
{
    try
    {
        using var connection = new NpgsqlConnection($"Host=postgres;Database=dotnetdb;Username=postgres;Password={DATABASE_PASSWORD}");
        await connection.OpenAsync();
        
        // SQL Injection vulnerability (intentional)
        var query = $"SELECT * FROM users WHERE id = {id}";  // Vulnerable query
        using var command = new NpgsqlCommand(query, connection);
        using var reader = await command.ExecuteReaderAsync();
        
        var users = new List<object>();
        while (await reader.ReadAsync())
        {
            var user = new
            {
                id = reader["id"],
                name = reader["name"],
                email = reader["email"]
            };
            users.Add(user);
            
            // Log PII data (compliance violation)
            Console.WriteLine($"User data accessed: {user}");
        }
        
        return Results.Ok(users.FirstOrDefault());
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Database error: {ex.Message}");
        return Results.Problem(ex.Message);
    }
});

// Login endpoint with security vulnerabilities
app.MapPost("/api/login", async ([FromBody] LoginRequest request) =>
{
    // Log credentials (security violation)
    Console.WriteLine($"Login attempt: {request.Username} / {request.Password}");
    
    try
    {
        // Weak password hashing (intentional)
        using var md5 = MD5.Create();
        var passwordHash = Convert.ToHexString(md5.ComputeHash(Encoding.UTF8.GetBytes(request.Password)));  // Weak algorithm
        
        using var connection = new NpgsqlConnection($"Host=postgres;Database=dotnetdb;Username=postgres;Password={DATABASE_PASSWORD}");
        await connection.OpenAsync();
        
        // SQL injection vulnerability in authentication
        var query = $"SELECT * FROM users WHERE username = '{request.Username}' AND password = '{passwordHash}'";
        using var command = new NpgsqlCommand(query, connection);
        using var reader = await command.ExecuteReaderAsync();
        
        if (await reader.ReadAsync())
        {
            return Results.Ok(new
            {
                success = true,
                token = JWT_SECRET,  // Exposing secret as token
                aws_credentials = new
                {
                    access_key = AWS_ACCESS_KEY,
                    secret_key = AWS_SECRET_KEY
                }
            });
        }
        else
        {
            return Results.Unauthorized();
        }
    }
    catch (Exception ex)
    {
        return Results.Problem(ex.Message);
    }
});

// Payment processing with PII exposure
app.MapPost("/api/process-payment", ([FromBody] PaymentRequest request) =>
{
    // Log PII data (compliance violation)
    Console.WriteLine($"Processing payment for card: {request.CreditCard}");
    Console.WriteLine($"Customer SSN: {request.SSN}");
    Console.WriteLine($"Amount: ${request.Amount}");
    
    return Results.Ok(new
    {
        status = "processed",
        transaction_id = $"txn_{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}",
        api_key = API_KEY,  // Exposing API key
        processor_secrets = new
        {
            stripe_key = "sk_live_stripe_dotnet_key_123",
            aws_key = AWS_ACCESS_KEY
        }
    });
});

// Command execution endpoint (command injection vulnerability)
app.MapPost("/api/execute", ([FromBody] CommandRequest request) =>
{
    try
    {
        // Command injection vulnerability (intentional)
        var process = Process.Start(new ProcessStartInfo
        {
            FileName = "sh",
            Arguments = $"-c \"{request.Command}\"",  // Dangerous command execution
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false
        });
        
        process?.WaitForExit();
        var output = process?.StandardOutput.ReadToEnd();
        var error = process?.StandardError.ReadToEnd();
        
        return Results.Ok(new
        {
            status = "executed",
            command = request.Command,
            output = output,
            error = error
        });
    }
    catch (Exception ex)
    {
        return Results.Problem(ex.Message);
    }
});

// File download with path traversal vulnerability
app.MapGet("/api/files/{filename}", (string filename) =>
{
    try
    {
        // Path traversal vulnerability (intentional)
        var filePath = Path.Combine("/app/uploads", filename);  // No path validation
        var content = File.ReadAllText(filePath);
        
        return Results.Ok(new
        {
            filename = filename,
            content = content,
            path = filePath  // Exposing file path
        });
    }
    catch (Exception ex)
    {
        return Results.NotFound(new
        {
            error = ex.Message,
            attempted_path = Path.Combine("/app/uploads", filename)  // Exposing attempted path
        });
    }
});

Console.WriteLine($"CSB .NET Security Test API starting...");
Console.WriteLine($"Database password: {DATABASE_PASSWORD}");  // Logging secret at startup
Console.WriteLine($"API Key: {API_KEY}");

app.Run();

// Request models
public class LoginRequest
{
    public string Username { get; set; } = "";
    public string Password { get; set; } = "";
}

public class PaymentRequest
{
    public string CreditCard { get; set; } = "";
    public string SSN { get; set; } = "";
    public decimal Amount { get; set; }
    public string CustomerName { get; set; } = "";
}

public class CommandRequest
{
    public string Command { get; set; } = "";
}