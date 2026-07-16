using IdentityService.Domain.Interfaces;
using MediatR;

namespace IdentityService.Application.Features.Auth.Queries;

public class LoginQueryHandler : IRequestHandler<LoginQuery, string>
{
    private readonly IUserRepository _userRepository;
    private readonly ITokenService _tokenService;
       private readonly IPasswordHasher _passwordHasher; // NEW!

   public LoginQueryHandler(IUserRepository userRepository, ITokenService tokenService, IPasswordHasher passwordHasher)
    {
        _userRepository = userRepository;
        _tokenService = tokenService;
        _passwordHasher = passwordHasher; // NEW!
    }

    public async Task<string> Handle(LoginQuery request, CancellationToken cancellationToken)
    {
        // 1. Find the user
        var user = await _userRepository.GetByMobileAsync(request.MobileNumber);
        
        if (user == null)
        {
            throw new UnauthorizedAccessException("Invalid mobile number or password.");
        }

         // 2. Verify Password using our clean interface!
        if (user.PasswordHash == null || !_passwordHasher.VerifyPassword(request.Password, user.PasswordHash))
        {
            throw new UnauthorizedAccessException("Invalid mobile number or password.");
        }

        // 3. Generate the JWT Wristband!
        var token = _tokenService.GenerateToken(user.Id, user.MobileNumber, user.FullName);

        return token;
    }
}