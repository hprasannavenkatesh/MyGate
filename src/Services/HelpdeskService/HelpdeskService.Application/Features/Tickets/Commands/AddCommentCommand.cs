using MediatR;

namespace HelpdeskService.Application.Features.Tickets.Commands;

public class AddCommentCommand : IRequest<Unit>
{
    public Guid TicketId { get; set; }
    public string CommentText { get; set; } = string.Empty;
    public bool IsAdminComment { get; set; } // Flutter will send false. Swagger will send true.

       // NEW: The Controller will pass this in
    public Guid UserId { get; set; } 
}