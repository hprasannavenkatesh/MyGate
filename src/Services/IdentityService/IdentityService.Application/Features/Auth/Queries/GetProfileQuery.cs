using MediatR;
using IdentityService.Domain;

namespace IdentityService.Application.Features.Auth.Queries;

public class GetProfileQuery : IRequest<UserProfileDto>
{
    public Guid UserId { get; set; }
}