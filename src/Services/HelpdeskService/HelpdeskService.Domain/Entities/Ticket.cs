using System;

namespace HelpdeskService.Domain.Entities;

public class Ticket
{
    public Guid Id { get; private set; } = Guid.Empty;
    public Guid SocietyId { get; private set; }
    public Guid FlatId { get; private set; }
    public Guid CreatedByUserId { get; private set; } // The resident who raised it
    
    public string Title { get; private set; } = null!;
    public string Description { get; private set; } = null!;
    public string? Category { get; private set; } // e.g., "Plumbing", "Electrical"
    
    public TicketPriority Priority { get; private set; } = TicketPriority.Medium;
    public TicketStatus Status { get; private set; } = TicketStatus.Open;
    
    public Guid? AssignedToId { get; private set; } // Admin or Staff member
    public string? ResolutionNotes { get; private set; }
    
    public int Rating { get; private set; } // 1 to 5 stars given by resident
    public string? Feedback { get; private set; }
    
    public DateTime CreatedAt { get; private set; }
    public DateTime? UpdatedAt { get; private set; }

  // NEW NAVIGATION PROPERTY FOR EF CORE:
    private readonly List<TicketComment> _comments = new();
    public IReadOnlyCollection<TicketComment> Comments => _comments.AsReadOnly();
    private Ticket() { }

    public Ticket(Guid societyId, Guid flatId, Guid createdByUserId, string title, string description, string? category = null, TicketPriority priority = TicketPriority.Medium)
    {
        if (string.IsNullOrWhiteSpace(title)) throw new ArgumentException("Title is required.");
        
        Id = Guid.NewGuid();
        SocietyId = societyId;
        FlatId = flatId;
        CreatedByUserId = createdByUserId;
        Title = title;
        Description = description;
        Category = category;
        Priority = priority;
        CreatedAt = DateTime.UtcNow;
    }

    public void AssignTo(Guid staffId)
    {
        AssignedToId = staffId;
        Status = TicketStatus.InProgress;
        UpdatedAt = DateTime.UtcNow;
    }

    public void Resolve(string resolutionNotes="")
    {
        ResolutionNotes = resolutionNotes;
        Status = TicketStatus.Resolved;
        UpdatedAt = DateTime.UtcNow;
    }

    public void Close()
    {
        Status = TicketStatus.Closed;
        UpdatedAt = DateTime.UtcNow;
    }
      public void AddComment(TicketComment comment)
    {
        _comments.Add(comment);
    }
}