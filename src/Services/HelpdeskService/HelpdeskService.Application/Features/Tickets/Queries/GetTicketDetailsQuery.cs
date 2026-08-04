using MediatR;
using HelpdeskService.Domain.Entities;
using HelpdeskService.Domain.Interfaces;


namespace HelpdeskService.Application.Features.Tickets.Queries;

public class GetTicketDetailsQuery : IRequest<Ticket?>
{
    public Guid TicketId { get; set; }
}

public class GetTicketDetailsQueryHandler : IRequestHandler<GetTicketDetailsQuery, Ticket?>
{
    private readonly ITicketRepository _repository;
    public GetTicketDetailsQueryHandler(ITicketRepository repository) => _repository = repository;

    public async Task<Ticket?> Handle(GetTicketDetailsQuery request, CancellationToken cancellationToken)
    {
        return await _repository.GetByIdWithCommentsAsync(request.TicketId);
    }
}