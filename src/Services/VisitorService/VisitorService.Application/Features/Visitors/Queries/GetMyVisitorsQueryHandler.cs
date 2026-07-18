using MediatR;
using VisitorService.Domain.Interfaces;
using VisitorService.Domain.Entities; // For PreApprovedVisitor

namespace VisitorService.Application.Features.Visitors.Queries;

public class GetMyVisitorsQueryHandler : IRequestHandler<GetMyVisitorsQuery, List<PreApprovedVisitor>>
{
    private readonly IPreApprovedVisitorRepository _repository;
    public GetMyVisitorsQueryHandler(IPreApprovedVisitorRepository repository) => _repository = repository;

    public async Task<List<PreApprovedVisitor>> Handle(GetMyVisitorsQuery request, CancellationToken cancellationToken)
    {
        return await _repository.GetByInviterIdAsync(request.InviterId);
    }
}