using MediatR;
using VisitorService.Domain.Interfaces;

namespace VisitorService.Application.Features.Visitors.Commands;

public class RegenerateOtpCommandHandler : IRequestHandler<RegenerateOtpCommand, RegenerateOtpResult>
{
    private readonly IPreApprovedVisitorRepository _visitorRepo;
    private readonly IPasswordHasher _passwordHasher;

    public RegenerateOtpCommandHandler(
        IPreApprovedVisitorRepository visitorRepo,
        IPasswordHasher passwordHasher)
    {
        _visitorRepo = visitorRepo;
        _passwordHasher = passwordHasher;
    }

    public async Task<RegenerateOtpResult> Handle(RegenerateOtpCommand request, CancellationToken cancellationToken)
    {
        // 1. Find the visitor
        var visitor = await _visitorRepo.GetByIdAsync(request.PreApprovalId)
            ?? throw new KeyNotFoundException("Visitor not found.");

        // 2. Only allow regenerating for Pending visitors
        if (visitor.Status != Domain.Entities.VisitorStatus.Pending)
            throw new InvalidOperationException(
                $"Cannot regenerate OTP for visitor with status '{visitor.Status}'. " +
                "Only Pending visitors can get a new OTP.");

        // 3. Generate new OTP
        var random = new Random();
        var otp = random.Next(1000, 9999).ToString();
        var hashedOtp = _passwordHasher.HashPassword(otp);

        // 4. Set the new OTP (also resets expiry to +30 mins)
        visitor.SetOtp(hashedOtp);

        // 5. Save to database
        await _visitorRepo.UpdateAsync(visitor);

        // 6. Print to console
        Console.WriteLine("");
        Console.WriteLine("**********************************************************");
        Console.WriteLine("*  OTP REGENERATED                                       *");
        Console.WriteLine("**********************************************************");
        Console.WriteLine($"*  Visitor         : {visitor.VisitorName}");
        Console.WriteLine($"*  New GATE OTP    : {otp}");
        Console.WriteLine($"*  Pre-Approval ID : {visitor.Id}");
        Console.WriteLine($"*  Expires At      : {visitor.OtpExpiresAt}");
        Console.WriteLine("**********************************************************");
        Console.WriteLine("");

        return new RegenerateOtpResult(otp, visitor.OtpExpiresAt!.Value);
    }
}