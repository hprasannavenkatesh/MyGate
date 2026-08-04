using MediatR;
using HelpdeskService.Domain.Entities;

namespace HelpdeskService.Application.Features.Tickets.Queries;

public class GetMyTicketsQuery : IRequest<List<Ticket>>
{
    public Guid FlatId { get; set; }
}