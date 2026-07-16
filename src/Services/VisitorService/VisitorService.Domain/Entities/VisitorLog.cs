using System;

namespace VisitorService.Domain.Entities;

public class VisitorLog
{
    public Guid Id { get; private set; } = Guid.Empty;
    public Guid SocietyId { get; private set; }
    
    // This links to the PreApprovedVisitor (if they were pre-approved). Can be null for unexpected guests!
    public Guid? PreApprovalId { get; private set; } 
    
    public string VisitorName { get; private set; } = null!;
    public string VisitorMobile { get; private set; } = null!;
    public string? Purpose { get; private set; }
    
    public Guid VisitingFlatId { get; private set; }
    public DateTime EntryTime { get; private set; }
    public DateTime? ExitTime { get; private set; }
    public VisitorStatus Status { get; private set; } = VisitorStatus.Inside;

    private VisitorLog() { }

    public VisitorLog(
        Guid societyId, 
        Guid? preApprovalId, 
        string visitorName, 
        string visitorMobile, 
        Guid visitingFlatId, 
        string? purpose = null)
    {
        Id = Guid.NewGuid();
        SocietyId = societyId;
        PreApprovalId = preApprovalId;
        VisitorName = visitorName;
        VisitorMobile = visitorMobile;
        VisitingFlatId = visitingFlatId;
        Purpose = purpose;
        EntryTime = DateTime.UtcNow;
    }

    public void MarkExit()
    {
       // if (Status != VisitorStatus.Inside) throw new InvalidOperationException("Visitor is not inside the society.");
        ExitTime = DateTime.UtcNow;
        Status = VisitorStatus.Exited;
    }
}