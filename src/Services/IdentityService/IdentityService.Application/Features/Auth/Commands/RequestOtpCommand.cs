using MediatR;

namespace IdentityService.Application.Features.Auth.Commands;

public class RequestOtpCommand : IRequest<Unit>
{
    public string MobileNumber { get; set; } = string.Empty;
}