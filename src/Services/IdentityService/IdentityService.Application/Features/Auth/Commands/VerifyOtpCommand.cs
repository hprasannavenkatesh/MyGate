using MediatR;

namespace IdentityService.Application.Features.Auth.Commands;

public class VerifyOtpCommand : IRequest<string>
{
    public string MobileNumber { get; set; } = string.Empty;
    public string Otp { get; set; } = string.Empty;
}