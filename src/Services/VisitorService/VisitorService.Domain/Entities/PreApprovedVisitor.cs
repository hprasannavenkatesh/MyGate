using System;

namespace VisitorService.Domain.Entities;

public class PreApprovedVisitor
{
    public Guid Id { get; private set; } = Guid.Empty;
    public Guid SocietyId { get; private set; }
    public Guid InvitedByUserId { get; private set; } // The resident
    public Guid FlatId { get; private set; }
    
    public string VisitorName { get; private set; } = null!;
    public string VisitorMobile { get; private set; } = null!;
    public string? Purpose { get; private set; }
    
    public DateTime ExpectedDate { get; private set; }
    public TimeSpan? ExpectedTime { get; private set; }
    
    public string? OtpHash { get; private set; } = null!;
    public DateTime? OtpExpiresAt { get; private set; }
    public VisitorStatus Status { get; private set; } = VisitorStatus.Pending;

    private PreApprovedVisitor() { }

    public PreApprovedVisitor(
        Guid societyId, 
        Guid invitedByUserId, 
        Guid flatId, 
        string visitorName, 
        string visitorMobile, 
        DateTime expectedDate, 
        TimeSpan? expectedTime = null,
        string? purpose = null)
    {
        if (string.IsNullOrWhiteSpace(visitorName)) throw new ArgumentException("Visitor name is required.");
        if (string.IsNullOrWhiteSpace(visitorMobile)) throw new ArgumentException("Visitor mobile is required.");

        Id = Guid.NewGuid();
        SocietyId = societyId;
        InvitedByUserId = invitedByUserId;
        FlatId = flatId;
        VisitorName = visitorName;
        VisitorMobile = visitorMobile;
        ExpectedDate = expectedDate;
        ExpectedTime = expectedTime;
        Purpose = purpose;
    }

    // Method to attach the OTP when generated
    public void SetOtp(string hashedOtp)
    {
        OtpHash = hashedOtp;
        OtpExpiresAt = DateTime.UtcNow.AddMinutes(30); // Gate OTPs usually last 30 mins
    }

     // The Handler will check the hash, and if valid, call this method to wipe it.
    public void ClearOtp()
    {
        OtpHash = null;
        OtpExpiresAt = null;
    }
}