using MediatR;
using HelpdeskService.Domain.Entities;
using HelpdeskService.Domain.Interfaces;

namespace HelpdeskService.Application.Features.Tickets.Commands;

public class RaiseTicketCommandHandler : IRequestHandler<RaiseTicketCommand, Guid>
{
    private readonly ITicketRepository _repository;
    public RaiseTicketCommandHandler(ITicketRepository repository) => _repository = repository;

    public async Task<Guid> Handle(RaiseTicketCommand request, CancellationToken cancellationToken)
    {
        // Convert int to Enum
        var priorityEnum = (TicketPriority)request.Priority;

        var ticket = new Ticket(
            request.SocietyId,
            request.FlatId,
           // Guid.Empty, // CreatedByUserId would come from JWT in a real app
             request.CreatedByUserId, // CHANGED: Was Guid.Empty, now uses the real ID!
            request.Title,
            request.Description,
            request.Category,
            priorityEnum
        );

        return (await _repository.AddAsync(ticket)).Id;
    }
}