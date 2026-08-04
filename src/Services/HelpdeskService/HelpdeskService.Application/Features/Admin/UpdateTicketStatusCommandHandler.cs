using MediatR;
using HelpdeskService.Domain.Entities;
using HelpdeskService.Domain.Interfaces;

namespace HelpdeskService.Application.Features.Admin;

public class UpdateTicketStatusCommandHandler : IRequestHandler<UpdateTicketStatusCommand, Unit>
{
    private readonly ITicketRepository _repository;
    public UpdateTicketStatusCommandHandler(ITicketRepository repository) => _repository = repository;

    public async Task<Unit> Handle(UpdateTicketStatusCommand request, CancellationToken cancellationToken)
    {
        var ticket = await _repository.GetByIdWithCommentsAsync(request.TicketId) 
            ?? throw new Exception("Ticket not found");

        if ((TicketStatus)request.NewStatus == TicketStatus.InProgress)
            ticket.AssignTo(request.AdminUserId);
        else if ((TicketStatus)request.NewStatus == TicketStatus.Resolved)
            ticket.Resolve();

        await _repository.UpdateAsync(ticket);
        return Unit.Value;
    }
}