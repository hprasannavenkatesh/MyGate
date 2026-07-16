using IdentityService.Domain.Interfaces;
using MediatR;

namespace IdentityService.Application.Features.Auth.Commands;

public class RequestOtpCommandHandler : IRequestHandler<RequestOtpCommand, Unit>
{
    private readonly IUserRepository _userRepository;
    private readonly IPasswordHasher _passwordHasher;

    public RequestOtpCommandHandler(IUserRepository userRepository, IPasswordHasher passwordHasher)
    {
        _userRepository = userRepository;
        _passwordHasher = passwordHasher;
    }

    public async Task<Unit> Handle(RequestOtpCommand request, CancellationToken cancellationToken)
    {
        var user = await _userRepository.GetByMobileAsync(request.MobileNumber);

        // SECURITY: Even if the user doesn't exist, return 200 OK. 
        // This prevents hackers from knowing which phone numbers are registered in our app!
        if (user != null)
        {
            // Generate a random 4-digit number
            var random = new Random();
            var otp = random.Next(1000, 9999).ToString();

            // Hash it and save it to the user
            var hashedOtp = _passwordHasher.HashPassword(otp);
            user.GenerateOtp(otp, hashedOtp);

            // In a real app, you would call a Twilio/AWS SNS service here to send an SMS.
            // For now, we will just print it to the terminal so we can test it!
            Console.WriteLine($"=========================================");
            Console.WriteLine($"📱 MOCK SMS SENT TO {request.MobileNumber}");
            Console.WriteLine($"🔑 YOUR OTP IS: {otp}");
            Console.WriteLine($"=========================================");

            // Save the hashed OTP to the database
            await _userRepository.UpdateAsync(user);
        }

        return Unit.Value;
    }
}