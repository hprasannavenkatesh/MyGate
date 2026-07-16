using MediatR;
using TenantService.Domain;
using TenantService.Domain.Interfaces;

namespace TenantService.Application.Features.Societies.Queries;

public class GetUserSocietiesQueryHandler : IRequestHandler<GetUserSocietiesQuery, List<UserSocietyDto>>
{
    private readonly ISocietyMemberRepository _repository;

    public GetUserSocietiesQueryHandler(ISocietyMemberRepository repository)
    {
        _repository = repository;
    }

    public async Task<List<UserSocietyDto>> Handle(GetUserSocietiesQuery request, CancellationToken cancellationToken)
    {
        // Just pass the userId to the repository and return the list!
        return await _repository.GetByUserIdAsync(request.UserId);
    }
}