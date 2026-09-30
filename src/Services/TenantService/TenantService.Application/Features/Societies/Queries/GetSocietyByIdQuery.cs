using MediatR;
using TenantService.Domain.Entities;

namespace TenantService.Application.Features.Societies.Queries;

public record GetSocietyByIdQuery : IRequest<Society?>
{
    public Guid Id { get; init; }
}

public class GetSocietyByIdQueryHandler : IRequestHandler<GetSocietyByIdQuery, Society?>
{
    private readonly Domain.Interfaces.ISocietyRepository _repo;
    public GetSocietyByIdQueryHandler(Domain.Interfaces.ISocietyRepository repo) => _repo = repo;

    public async Task<Society?> Handle(GetSocietyByIdQuery request, CancellationToken cancellationToken)
        => await _repo.GetByIdAsync(request.Id, cancellationToken);
}