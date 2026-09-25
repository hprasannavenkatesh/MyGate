using MediatR;
using VisitorService.Domain.Interfaces;
using VisitorService.Domain.Entities;

namespace VisitorService.Application.Features.Visitors.Queries;

public class GetSocietyVisitorsQueryHandler : IRequestHandler<GetSocietyVisitorsQuery, List<PreApprovedVisitor>>
{
    private readonly IPreApprovedVisitorRepository _repository;

    public GetSocietyVisitorsQueryHandler(IPreApprovedVisitorRepository repository)
    {
        _repository = repository;
    }

    public async Task<List<PreApprovedVisitor>> Handle(GetSocietyVisitorsQuery request, CancellationToken cancellationToken)
    {
        return await _repository.GetBySocietyIdAsync(request.SocietyId);
    }
}