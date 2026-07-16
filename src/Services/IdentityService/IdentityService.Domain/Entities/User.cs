using System;
using IdentityService.Domain.Interfaces;

namespace IdentityService.Domain.Entities;

public class User
{
    // Guid is a globally unique identifier (e.g., "3f4b2c1d-8e5f-4a9b...")
    public Guid Id { get; private set; }= Guid.Empty;
    
    public string MobileNumber { get; private set; } =null!;
    public string? Email { get; private set; }
    public string FullName { get; private set; } = null!;
    
    public string? PasswordHash { get; private set; } = null!;
    
    public bool IsMobileVerified { get; private set; }
    public bool IsEmailVerified { get; private set; }

    public string? OtpHash { get; private set; } = null!;
    public DateTime? OtpExpiresAt { get; private set; }
    
    public DateTime? LastLoginAt { get; private set; }
    public DateTime CreatedAt { get; private set; }

    // EF Core requires a parameterless constructor to read data from the database.
    // We make it 'private' so developers can't use it to create a blank user.
    private User() { }

    // This is the ONLY way a new User can be created in our app.
    public User(string mobileNumber, string fullName, string? email = null)
    {
        // Business Rule: Mobile number is strictly required
        if (string.IsNullOrWhiteSpace(mobileNumber))
            throw new ArgumentException("Mobile number cannot be empty.", nameof(mobileNumber));

        Id = Guid.NewGuid();
        MobileNumber = mobileNumber;
        FullName = fullName;
        Email = email;
        
        IsMobileVerified = false;
        IsEmailVerified = false;
        CreatedAt = DateTime.UtcNow;
    }

    // A method to update the password securely
    public void SetPasswordHash(string passwordHash)
    {
        if (string.IsNullOrWhiteSpace(passwordHash))
            throw new ArgumentException("Password hash cannot be empty.");
            
        PasswordHash = passwordHash;
    }

    // A method to mark the mobile as verified
    public void VerifyMobile()
    {
        IsMobileVerified = true;
    }

        public void UpdateProfile(string fullName, string? email)
    {
        if (string.IsNullOrWhiteSpace(fullName))
            throw new ArgumentException("Full name cannot be empty.");
            
        FullName = fullName;
        Email = email;
    }

        public void GenerateOtp(string plainTextOtp, string hashedOtp)
    {
        // Save the hash, not the plain text!
        OtpHash = hashedOtp;
        // OTP is valid for 5 minutes
        OtpExpiresAt = DateTime.UtcNow.AddMinutes(5); 
    }

       public bool VerifyOtp(string plainTextOtp, IPasswordHasher hasher)
    {
        // 1. Did they even request an OTP?
        if (OtpHash == null || OtpExpiresAt == null) return false;

        // 2. Has the OTP expired?
        if (DateTime.UtcNow > OtpExpiresAt) return false;

        // 3. Does the hash match? (Use the clean interface!)
        var isMatch = hasher.VerifyPassword(plainTextOtp, OtpHash);
        
        if (isMatch)
        {
            // Clear the OTP so it can't be used again (Replay Attack prevention)
            OtpHash = null;
            OtpExpiresAt = null;
            return true;
        }

        return false;
    }
}