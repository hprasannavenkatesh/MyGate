namespace NoticeBoardService.Domain.Entities;

public class Notice
{
    public Guid Id { get; private set; }
    public Guid SocietyId { get; private set; }
    public string Title { get; private set; }
    public string Description { get; private set; }
    public NoticeCategory Category { get; private set; }
    public bool IsPinned { get; private set; }
    public Guid CreatedByUserId { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? ExpiresAt { get; private set; }

    private Notice() { } // For EF Core

    public Notice(
        Guid societyId,
        string title,
        string description,
        NoticeCategory category,
        bool isPinned,
        Guid createdByUserId,
        DateTime? expiresAt = null)
    {
        Id = Guid.NewGuid();
        SocietyId = societyId;
        Title = title;
        Description = description;
        Category = category;
        IsPinned = isPinned;
        CreatedByUserId = createdByUserId;
        CreatedAt = DateTime.UtcNow;
        ExpiresAt = expiresAt;
    }

    public void Pin() => IsPinned = true;
    public void Unpin() => IsPinned = false;
}