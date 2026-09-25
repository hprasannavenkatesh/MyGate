using MediatR;
using VisitorService.Domain.Interfaces;

namespace VisitorService.Application.Features.Visitors.Commands;

public class ManualEntryCommandHandler : IRequestHandler<ManualEntryCommand, Unit>
{
   private readonly IPreApprovedVisitorRepository _visitorRepo;
    private readonly IVisitorLogRepository _logRepo;

    public ManualEntryCommandHandler(IPreApprovedVisitorRepository visitorRepo,  IVisitorLogRepository logRepo)
    {
        _visitorRepo = visitorRepo;
        _logRepo = logRepo;
    }

    public async Task<Unit> Handle(ManualEntryCommand request, CancellationToken cancellationToken)
    {
        // 1. Find the visitor
        var visitor = await _visitorRepo.GetByIdAsync(request.PreApprovalId)
            ?? throw new KeyNotFoundException("Visitor not found.");

        // 2. Manual entry — no OTP check, admin override
        visitor.ManualEntry();
        await _visitorRepo.UpdateAsync(visitor);

        // 3. Create visitor log with manual entry note
        var log = new Domain.Entities.VisitorLog(
            visitor.SocietyId,
            visitor.Id,
            visitor.VisitorName,
            visitor.VisitorMobile,
            visitor.FlatId,
            $"MANUAL ENTRY by Admin. Reason: {request.Reason}"
        );

        await _logRepo.AddAsync(log);

        Console.WriteLine("");
        Console.WriteLine("**********************************************************");
        Console.WriteLine("*  MANUAL ENTRY (Admin Override)                         *");
        Console.WriteLine("**********************************************************");
        Console.WriteLine($"*  Visitor : {visitor.VisitorName}");
        Console.WriteLine($"*  Reason  : {request.Reason}");
        Console.WriteLine("**********************************************************");
        Console.WriteLine("");

        return Unit.Value;
    }
}