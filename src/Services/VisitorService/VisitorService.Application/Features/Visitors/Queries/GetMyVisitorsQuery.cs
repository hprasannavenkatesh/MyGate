using MediatR;
using VisitorService.Domain.Entities;

namespace VisitorService.Application.Features.Visitors.Queries;

public class GetMyVisitorsQuery : IRequest<List<PreApprovedVisitor>>
{
    public Guid InviterId { get; set; }
}