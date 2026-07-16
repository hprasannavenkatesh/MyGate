/*using MediatR;
using VisitorService.Domain.Entities;
using VisitorService.Domain.Interfaces;

namespace VisitorService.Application.Features.Visitors.Commands;

public class VerifyVisitorOtpCommandHandler : IRequestHandler<VerifyVisitorOtpCommand, Guid>
{
    private readonly IPreApprovedVisitorRepository _visitorRepo;
    private readonly IPasswordHasher _passwordHasher;
    // We'll need a log repository too!

    public VerifyVisitorOtpCommandHandler(IPreApprovedVisitorRepository visitorRepo, IPasswordHasher passwordHasher)
    {
        _visitorRepo = visitorRepo;
        _passwordHasher = passwordHasher;
    }

    public async Task<Guid> Handle(VerifyVisitorOtpCommand request, CancellationToken cancellationToken)
    {
        // 1. Find the pre-approved visitor
        var visitor = await _visitorRepo.GetByIdAsync(request.PreApprovalId)
            ?? throw new KeyNotFoundException("Visitor not found.");

        // 2. Verify the OTP using our clean architecture rule!
        // The Handler checks the hash, then tells the entity to clear it if valid.
        bool isValid = _passwordHasher.VerifyPassword(request.Otp, visitor.OtpHash!);

        if (!isValid)
            throw new UnauthorizedAccessException("Invalid or expired OTP.");

        // 3. Clear the OTP in the domain entity
        visitor.ClearOtp();

        // 4. In a real app, we would inject IVisitorLogRepository here and save a new VisitorLog
        // to record that they stepped inside. For now, we just return success!
        
        Console.WriteLine($"🚪 GATE LOG: {visitor.VisitorName} entered the society at {DateTime.UtcNow}");

        return visitor.Id;
    }
}
*/
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

        // 2. Verify the OTP
        bool isValid = _passwordHasher.VerifyPassword(request.Otp, visitor.OtpHash!);

        if (!isValid)
            throw new UnauthorizedAccessException("Invalid or expired OTP.");

        // 3. Clear the OTP in the domain entity
        visitor.ClearOtp();

        // 4. CREATE THE REAL DATABASE LOG!
        var log = new VisitorLog(
            visitor.SocietyId,
            visitor.Id, // Link the log to the pre-approval
            visitor.VisitorName,
            visitor.VisitorMobile,
            visitor.FlatId,
            visitor.Purpose
        );

        // 5. Save the log to the database
        var savedLog = await _logRepo.AddAsync(log);

        Console.WriteLine($"🚪 GATE LOG SAVED: {visitor.VisitorName} entered. Log ID: {savedLog.Id}");

        // We return the Log ID, because the guard needs it to mark them as "Exited" later!
        return savedLog.Id; 
    }
}