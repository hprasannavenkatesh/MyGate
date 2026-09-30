using IdentityService.Domain.Interfaces;
using MediatR;
using Microsoft.Extensions.Logging;

namespace IdentityService.Application.Features.Auth.Queries;

public class LookupUserByMobileQueryHandler 
    : IRequestHandler<LookupUserByMobileQuery, UserLookupDto?>
{
    private readonly IUserRepository _userRepository;
    private readonly ILogger<LookupUserByMobileQueryHandler> _logger;

    public LookupUserByMobileQueryHandler(
        IUserRepository userRepository,
        ILogger<LookupUserByMobileQueryHandler> logger)
    {
        _userRepository = userRepository;
        _logger = logger;
    }

    public async Task<UserLookupDto?> Handle(
        LookupUserByMobileQuery request, 
        CancellationToken cancellationToken)
    {
        var user = await _userRepository.GetByMobileAsync(request.MobileNumber);

        if (user is null)
        {
            _logger.LogInformation("User lookup: no user found for {Mobile}", request.MobileNumber);
            return null;
        }

        return new UserLookupDto(
            user.Id,
            user.FullName,
            user.MobileNumber,
            user.Email,
            user.IsMobileVerified
        );
    }
}