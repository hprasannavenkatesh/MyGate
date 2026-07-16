using MediatR;
using TenantService.Domain;

namespace TenantService.Application.Features.Societies.Queries;

public class GetUserSocietiesQuery : IRequest<List<UserSocietyDto>>
{
    public Guid UserId { get; set; }
}