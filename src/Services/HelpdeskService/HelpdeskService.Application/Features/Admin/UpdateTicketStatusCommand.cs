using MediatR;

namespace HelpdeskService.Application.Features.Admin;

public class UpdateTicketStatusCommand : IRequest<Unit>
{
    public Guid TicketId { get; set; }
    public int NewStatus { get; set; } // 1=InProgress, 2=Resolved
    public Guid AdminUserId { get; set; }
}