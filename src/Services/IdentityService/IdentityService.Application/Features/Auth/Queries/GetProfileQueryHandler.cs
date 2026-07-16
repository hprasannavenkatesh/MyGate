using IdentityService.Domain;
using IdentityService.Domain.Interfaces;
using MediatR;

namespace IdentityService.Application.Features.Auth.Queries;

public class GetProfileQueryHandler : IRequestHandler<GetProfileQuery, UserProfileDto>
{
    private readonly IUserRepository _userRepository;

    public GetProfileQueryHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<UserProfileDto> Handle(GetProfileQuery request, CancellationToken cancellationToken)
    {
        var user = await _userRepository.GetByIdAsync(request.UserId)
            ?? throw new KeyNotFoundException("User not found.");

        return new UserProfileDto
        {
            Id = user.Id,
            MobileNumber = user.MobileNumber,
            FullName = user.FullName,
            Email = user.Email,
            IsMobileVerified = user.IsMobileVerified
        };
    }
}