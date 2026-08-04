using MediatR;

namespace HelpdeskService.Application.Features.Tickets.Commands;

public class RaiseTicketCommand : IRequest<Guid>
{
    public Guid SocietyId { get; set; }
    public Guid FlatId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? Category { get; set; }
    public int Priority { get; set; } = 2; // Default to Medium
      public Guid CreatedByUserId { get; set; } // ADD THIS LINE
}