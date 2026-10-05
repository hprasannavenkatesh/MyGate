using MediatR;
using HelpdeskService.Domain.Entities;

namespace HelpdeskService.Application.Features.Tickets.Queries;

public class GetSocietyTicketsQuery : IRequest<List<Ticket>>
{
    public Guid SocietyId { get; set; }
}