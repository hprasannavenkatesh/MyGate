using MediatR;
using HelpdeskService.Domain.Interfaces;
using HelpdeskService.Domain.Entities;

namespace HelpdeskService.Application.Features.Tickets.Queries;

public class GetSocietyTicketsQueryHandler : IRequestHandler<GetSocietyTicketsQuery, List<Ticket>>
{
    private readonly ITicketRepository _repository;
    public GetSocietyTicketsQueryHandler(ITicketRepository repository) => _repository = repository;

    public async Task<List<Ticket>> Handle(GetSocietyTicketsQuery request, CancellationToken cancellationToken)
    {
        return await _repository.GetBySocietyIdAsync(request.SocietyId);
    }
}