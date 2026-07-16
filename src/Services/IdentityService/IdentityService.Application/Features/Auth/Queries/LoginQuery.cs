using MediatR;

namespace IdentityService.Application.Features.Auth.Queries;

// A Query asks for data and returns a string (the Token)
public class LoginQuery : IRequest<string>
{
    public string MobileNumber { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}