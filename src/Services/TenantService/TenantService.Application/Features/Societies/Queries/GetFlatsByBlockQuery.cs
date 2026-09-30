using MediatR;
using TenantService.Domain.Entities;

namespace TenantService.Application.Features.Societies.Queries;

public record GetFlatsByBlockQuery : IRequest<IReadOnlyList<Flat>>
{
    public Guid BlockId { get; init; }
}

public class GetFlatsByBlockQueryHandler : IRequestHandler<GetFlatsByBlockQuery, IReadOnlyList<Flat>>
{
    private readonly Domain.Interfaces.IFlatRepository _repo;
    public GetFlatsByBlockQueryHandler(Domain.Interfaces.IFlatRepository repo) => _repo = repo;

    public async Task<IReadOnlyList<Flat>> Handle(GetFlatsByBlockQuery request, CancellationToken cancellationToken)
        => await _repo.GetFlatsByBlockAsync(request.BlockId, cancellationToken);
}