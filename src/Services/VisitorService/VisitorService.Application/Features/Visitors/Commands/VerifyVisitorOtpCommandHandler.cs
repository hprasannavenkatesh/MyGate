using MediatR;
using VisitorService.Domain.Entities;
using VisitorService.Domain.Interfaces;

namespace VisitorService.Application.Features.Visitors.Commands;

public class VerifyVisitorOtpCommandHandler : IRequestHandler<VerifyVisitorOtpCommand, Guid>
{
    private readonly IPreApprovedVisitorRepository _visitorRepo;
    private readonly IVisitorLogRepository _logRepo; // NEW!
    private readonly IPasswordHasher _passwordHasher;

    public VerifyVisitorOtpCommandHandler(
        IPreApprovedVisitorRepository visitorRepo,
        IVisitorLogRepository logRepo, // NEW!
        IPasswordHasher passwordHasher)
    {
        _visitorRepo = visitorRepo;
        _logRepo = logRepo; // NEW!
        _passwordHasher = passwordHasher;
    }


    public async Task<Guid> Handle(VerifyVisitorOtpCommand request, CancellationToken cancellationToken)
    {
        // 1. Find the pre-approved visitor
        var visitor = await _visitorRepo.GetByIdAsync(request.PreApprovalId)
            ?? throw new KeyNotFoundException("Visitor not found.");

        // 2. CHECK THE EXPIRATION TIME! (The missing rule)
        if (visitor.OtpExpiresAt == null || DateTime.UtcNow > visitor.OtpExpiresAt.Value)
        {
            throw new UnauthorizedAccessException("OTP has expired.");
        }
    

        // 3. Verify OTP hash
        if (string.IsNullOrEmpty(visitor.OtpHash) || !_passwordHasher.VerifyPassword(request.Otp, visitor.OtpHash))
            throw new UnauthorizedAccessException("Invalid OTP.");

        // 4. Clear the OTP in the domain entity
        visitor.ClearOtp();
        // 5.3 NEW: Update status to Inside
        visitor.MarkAsEntered();
        await _visitorRepo.UpdateAsync(visitor);

        // 5. Create the real database log
        var log = new VisitorLog(
            visitor.SocietyId,
            visitor.Id,
            visitor.VisitorName,
            visitor.VisitorMobile,
            visitor.FlatId,
            visitor.Purpose
        );

        var savedLog = await _logRepo.AddAsync(log);
        Console.WriteLine($"🚪 GATE LOG SAVED: {visitor.VisitorName} entered. Log ID: {savedLog.Id}");
        Console.WriteLine("==========================================================");
        Console.WriteLine($"GATE ENTRY: {visitor.VisitorName} entered the society.");
        Console.WriteLine($"Log ID: {savedLog.Id}");
        Console.WriteLine("==========================================================");

        return savedLog.Id;
    }
}