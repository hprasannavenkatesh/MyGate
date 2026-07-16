using MediatR;

namespace IdentityService.Application.Features.Auth.Commands;

// This is the data package being sent to MediatR
public class RegisterUserCommand : IRequest<Guid>
{
    public string MobileNumber { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? Email { get; set; }
        public string Password { get; set; } = string.Empty; // NEW!
}