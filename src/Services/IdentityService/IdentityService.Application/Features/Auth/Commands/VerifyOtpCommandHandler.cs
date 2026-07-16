using IdentityService.Domain.Interfaces;
using MediatR;

namespace IdentityService.Application.Features.Auth.Commands;

public class VerifyOtpCommandHandler : IRequestHandler<VerifyOtpCommand, string>
{
    private readonly IUserRepository _userRepository;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ITokenService _tokenService;

    public VerifyOtpCommandHandler(
        IUserRepository userRepository, 
        IPasswordHasher passwordHasher,
        ITokenService tokenService)
    {
        _userRepository = userRepository;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
    }

    public async Task<string> Handle(VerifyOtpCommand request, CancellationToken cancellationToken)
    {
        // 1. Find the user
        var user = await _userRepository.GetByMobileAsync(request.MobileNumber)
            ?? throw new UnauthorizedAccessException("Invalid mobile number or OTP.");

        // 2. Verify the OTP using our clean Domain method!
        // Notice we pass the _passwordHasher into the entity method.
        bool isValid = user.VerifyOtp(request.Otp, _passwordHasher);

        if (!isValid)
        {
            throw new UnauthorizedAccessException("Invalid or expired OTP.");
        }

        // 3. Save the user to DB (This clears the OtpHash so it can't be used again!)
        await _userRepository.UpdateAsync(user);

        // 4. Generate the JWT Wristband!
        var token = _tokenService.GenerateToken(user.Id, user.MobileNumber, user.FullName);

        return token;
    }
}