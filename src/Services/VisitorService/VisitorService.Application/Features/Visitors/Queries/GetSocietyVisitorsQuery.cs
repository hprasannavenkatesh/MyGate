using MediatR;
using VisitorService.Domain.Entities;

namespace VisitorService.Application.Features.Visitors.Queries;

public class GetSocietyVisitorsQuery : IRequest<List<PreApprovedVisitor>>
{
    public Guid SocietyId { get; set; }
}