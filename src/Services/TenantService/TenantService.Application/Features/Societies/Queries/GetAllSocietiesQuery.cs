using MediatR;
using TenantService.Domain.Entities;

namespace TenantService.Application.Features.Societies.Queries;

public record GetAllSocietiesQuery : IRequest<IReadOnlyList<Society>>;

public class GetAllSocietiesQueryHandler : IRequestHandler<GetAllSocietiesQuery, IReadOnlyList<Society>>
{
    private readonly Domain.Interfaces.ISocietyRepository _repo;
    public GetAllSocietiesQueryHandler(Domain.Interfaces.ISocietyRepository repo) => _repo = repo;

    public async Task<IReadOnlyList<Society>> Handle(GetAllSocietiesQuery request, CancellationToken cancellationToken)
        => await _repo.GetAllAsync(cancellationToken);
}