using MediatR;

namespace IdentityService.Application.Features.Auth.Commands;

public class UpdateProfileCommand : IRequest<Unit>
{
    public Guid UserId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? Email { get; set; }
}