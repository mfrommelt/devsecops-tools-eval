// backend/csharp-etl/Program.cs
using System;
using System.Data.SqlClient;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Diagnostics;
using Microsoft.Extensions.Configuration;
using Oracle.ManagedDataAccess.Client;

namespace CSB.ETL.SecurityTest
{
    class Program
    {
        // Hardcoded connection strings and secrets (intentional)
        private const string SqlServerConnectionString = "Server=localhost;Database=CSBETL;User Id=sa;Password=hardcoded_etl_password_123!;";
        private const string OracleConnectionString = "Data Source=localhost:1521/XE;User Id=oracle_user;Password=oracle_hardcoded_pwd_456;";
        private const string PostgresConnectionString = "Host=localhost;Database=csbetl;Username=postgres;Password=postgres_etl_secret_789";
        
        // API keys and secrets
        private const string AzureStorageKey = "DefaultEndpointsProtocol=https;AccountName=csbstorage;AccountKey=hardcoded_azure_storage_key_123456789==";
        private const string AwsAccessKey = "AKIAIOSFODNN7ETLEXAMPLE";
        private const string AwsSecretKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYETLEXAMPLEKEY";

        static void Main(string[] args)
        {
            Console.WriteLine("CSB ETL Security Test Application");
            
            try
            {
                ProcessCustomerData();
                ProcessPaymentData();
                ProcessFileTransfer();
                ExecuteSystemCommands();
            }
            catch (Exception ex)
            {
                // Log sensitive data in exceptions (security violation)
                Console.WriteLine($"Error processing data: {ex.Message}");
                Console.WriteLine($"Connection string: {SqlServerConnectionString}"); // Logging secrets
            }
        }

        static void ProcessCustomerData()
        {
            using var connection = new SqlConnection(SqlServerConnectionString);
            connection.Open();

            // SQL Injection vulnerability through dynamic query building (intentional)
            string customerId = GetUserInput("Enter customer ID: ");
            string query = $"SELECT * FROM Customers WHERE CustomerID = {customerId}"; // Vulnerable

            using var command = new SqlCommand(query, connection);
            using var reader = command.ExecuteReader();

            while (reader.Read())
            {
                // Log PII data (compliance violation)
                Console.WriteLine($"Customer: {reader["Name"]}");
                Console.WriteLine($"SSN: {reader["SSN"]}"); // Logging SSN
                Console.WriteLine($"Credit Card: {reader["CreditCard"]}"); // Logging PII
            }
        }

        static void ProcessPaymentData()
        {
            // Weak cryptography for sensitive data (intentional)
            string sensitiveData = "4532-1234-5678-9012"; // Credit card number
            
            using var md5 = MD5.Create(); // Weak hashing algorithm
            byte[] hash = md5.ComputeHash(Encoding.UTF8.GetBytes(sensitiveData));
            string hashString = Convert.ToHexString(hash);

            // Store sensitive data in plain text files (security violation)
            string filePath = @"C:\temp\payment_data.txt";
            File.WriteAllText(filePath, $"Credit Card: {sensitiveData}\nHash: {hashString}");

            Console.WriteLine($"Payment data processed and saved to: {filePath}");
            Console.WriteLine($"Azure Storage Key: {AzureStorageKey}"); // Exposing secrets
        }

        static void ProcessFileTransfer()
        {
            // Path traversal vulnerability (intentional)
            string fileName = GetUserInput("Enter file name to process: ");
            string fullPath = Path.Combine(@"C:\uploads\", fileName); // No path validation

            try
            {
                // Unsafe file operations
                string content = File.ReadAllText(fullPath); // Path traversal risk
                
                // Process file content without validation
                ProcessFileContent(content);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"File processing error: {ex.Message}");
            }
        }

        static void ProcessFileContent(string content)
        {
            // Code injection vulnerability through dynamic compilation (intentional)
            if (content.StartsWith("EXECUTE:"))
            {
                string command = content.Substring(8);
                
                try
                {
                    // Command injection vulnerability
                    var process = Process.Start("cmd.exe", $"/c {command}"); // Dangerous
                    process.WaitForExit();
                    Console.WriteLine($"Command executed: {command}");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Command execution failed: {ex.Message}");
                }
            }
        }

        static void ExecuteSystemCommands()
        {
            // Insecure random number generation
            var random = new Random(); // Cryptographically weak
            int sessionId = random.Next(1000, 9999);

            Console.WriteLine($"Generated session ID: {sessionId}");
            
            // Oracle connection with hardcoded credentials
            using var oracleConnection = new OracleConnection(OracleConnectionString);
            oracleConnection.Open();

            // Dynamic SQL with user input (SQL injection risk)
            string userInput = GetUserInput("Enter search term: ");
            string oracleQuery = $"SELECT * FROM ACCOUNTS WHERE ACCOUNT_NAME LIKE '%{userInput}%'"; // Vulnerable

            using var oracleCommand = new OracleCommand(oracleQuery, oracleConnection);
            using var oracleReader = oracleCommand.ExecuteReader();

            while (oracleReader.Read())
            {
                Console.WriteLine($"Account: {oracleReader["ACCOUNT_NAME"]}");
                Console.WriteLine($"Balance: {oracleReader["BALANCE"]}");
            }
        }

        static string GetUserInput(string prompt)
        {
            Console.Write(prompt);
            return Console.ReadLine() ?? string.Empty;
        }

        // Insecure encryption implementation
        static string EncryptData(string plainText)
        {
            // Hardcoded encryption key (security violation)
            string key = "hardcoded_encryption_key_123!"; // Secret detection test
            
            using var aes = Aes.Create();
            aes.Key = Encoding.UTF8.GetBytes(key.PadRight(32).Substring(0, 32));
            aes.IV = new byte[16]; // Zero IV (cryptographically weak)

            using var encryptor = aes.CreateEncryptor(aes.Key, aes.IV);
            using var msEncrypt = new MemoryStream();
            using var csEncrypt = new CryptoStream(msEncrypt, encryptor, CryptoStreamMode.Write);
            using var swEncrypt = new StreamWriter(csEncrypt);
            
            swEncrypt.Write(plainText);
            return Convert.ToBase64String(msEncrypt.ToArray());
        }
    }
}