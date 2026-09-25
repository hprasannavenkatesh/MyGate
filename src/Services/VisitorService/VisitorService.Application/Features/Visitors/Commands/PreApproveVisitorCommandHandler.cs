using MediatR;
using VisitorService.Domain.Entities;
using VisitorService.Domain.Interfaces;

namespace VisitorService.Application.Features.Visitors.Commands;

public class PreApproveVisitorCommandHandler : IRequestHandler<PreApproveVisitorCommand, PreApproveVisitorResult>
{
    private readonly IPreApprovedVisitorRepository _repository;
    private readonly IPasswordHasher _passwordHasher;

    public PreApproveVisitorCommandHandler(IPreApprovedVisitorRepository repository, IPasswordHasher passwordHasher)
    {
        _repository = repository;
        _passwordHasher = passwordHasher;
    }

   // public async Task<Guid> Handle(PreApproveVisitorCommand request, CancellationToken cancellationToken)
    public async Task<PreApproveVisitorResult> Handle(PreApproveVisitorCommand request, CancellationToken cancellationToken)
    {
        // 1. Create the Visitor Entity
        var visitor = new PreApprovedVisitor(
            request.SocietyId,
            request.InvitedByUserId != Guid.Empty ? request.InvitedByUserId : Guid.Empty, // Use provided InvitedByUserId or default to Guid.Empty
            request.FlatId,
            request.VisitorName,
            request.VisitorMobile,
            request.ExpectedDate,
            request.ExpectedTime,
            request.Purpose
        );

        // 2. Generate Gate OTP
        var random = new Random();
        var otp = random.Next(1000, 9999).ToString();
        var hashedOtp = _passwordHasher.HashPassword(otp);
        
        visitor.SetOtp(hashedOtp);

        // 3. Save to Database
        var result = await _repository.AddAsync(visitor);

        // 4. In a real app, send SMS to visitor with the OTP!
        /*Console.WriteLine($"=========================================");
        Console.WriteLine($"📱 MOCK SMS TO VISITOR: {request.VisitorMobile}");
        Console.WriteLine($"🔑 GATE OTP: {otp}");
        Console.WriteLine($"=========================================");
        */
Console.WriteLine("");
Console.WriteLine("**********************************************************");
Console.WriteLine("*  VISITOR PRE-APPROVED - GATE OTP GENERATED             *");
Console.WriteLine("**********************************************************");
Console.WriteLine($"*  Visitor Mobile : {request.VisitorMobile}");
Console.WriteLine($"*  GATE OTP       : {otp}  <--- USE THIS OTP TO VERIFY ENTRY");
Console.WriteLine($"*  Pre-Approval ID: {result.Id}");
Console.WriteLine("**********************************************************");
Console.WriteLine("");
        return new PreApproveVisitorResult(result.Id, otp);
       // return result.Id;
    }
}