using MediatR;
using TenantService.Domain.Entities;

namespace TenantService.Application.Features.Societies.Queries;

public record GetBlocksBySocietyQuery : IRequest<IReadOnlyList<Block>>
{
    public Guid SocietyId { get; init; }
}

public class GetBlocksBySocietyQueryHandler : IRequestHandler<GetBlocksBySocietyQuery, IReadOnlyList<Block>>
{
    private readonly Domain.Interfaces.IFlatRepository _repo;
    public GetBlocksBySocietyQueryHandler(Domain.Interfaces.IFlatRepository repo) => _repo = repo;

    public async Task<IReadOnlyList<Block>> Handle(GetBlocksBySocietyQuery request, CancellationToken cancellationToken)
        => await _repo.GetBlocksBySocietyAsync(request.SocietyId, cancellationToken);
}