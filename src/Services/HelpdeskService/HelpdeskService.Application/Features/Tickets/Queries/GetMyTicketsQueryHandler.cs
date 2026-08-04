using MediatR;
using HelpdeskService.Domain.Interfaces;
using HelpdeskService.Domain.Entities;

namespace HelpdeskService.Application.Features.Tickets.Queries;

public class GetMyTicketsQueryHandler : IRequestHandler<GetMyTicketsQuery, List<Ticket>>
{
    private readonly ITicketRepository _repository;
    public GetMyTicketsQueryHandler(ITicketRepository repository) => _repository = repository;

    public async Task<List<Ticket>> Handle(GetMyTicketsQuery request, CancellationToken cancellationToken)
    {
        return await _repository.GetByFlatIdAsync(request.FlatId);
    }
}