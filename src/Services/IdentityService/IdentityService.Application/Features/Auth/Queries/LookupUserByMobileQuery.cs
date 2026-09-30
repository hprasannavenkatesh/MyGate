using MediatR;

namespace IdentityService.Application.Features.Auth.Queries;

public class LookupUserByMobileQuery : IRequest<UserLookupDto?>
{
    public string MobileNumber { get; set; } = string.Empty;
}

public record UserLookupDto(
    Guid UserId,
    string FullName,
    string MobileNumber,
    string? Email,
    bool IsMobileVerified
);