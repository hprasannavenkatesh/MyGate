using System;

namespace HelpdeskService.Domain.Entities;

public class TicketComment
{
    public Guid Id { get; private set; } = Guid.Empty;
    public Guid TicketId { get; private set; }
    public Guid UserId { get; private set; } // Can be resident or admin
    public string CommentText { get; private set; } = null!;
    public bool IsAdminComment { get; private set; } // To highlight admin responses
    public string? AttachmentUrl { get; private set; }
    public DateTime CreatedAt { get; private set; }

    private TicketComment() { }

    public TicketComment(Guid ticketId, Guid userId, string commentText, bool isAdminComment = false, string? attachmentUrl = null)
    {
        if (string.IsNullOrWhiteSpace(commentText)) throw new ArgumentException("Comment cannot be empty.");
        
        Id = Guid.NewGuid();
        TicketId = ticketId;
        UserId = userId;
        CommentText = commentText;
        IsAdminComment = isAdminComment;
        AttachmentUrl = attachmentUrl;
        CreatedAt = DateTime.UtcNow;
    }
}