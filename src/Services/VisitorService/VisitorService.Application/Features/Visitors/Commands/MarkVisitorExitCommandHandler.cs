using MediatR;
using VisitorService.Domain.Entities;
using VisitorService.Domain.Interfaces;

namespace VisitorService.Application.Features.Visitors.Commands;

public class MarkVisitorExitCommandHandler : IRequestHandler<MarkVisitorExitCommand, Unit>
{
    private readonly IVisitorLogRepository _logRepo;
    private readonly IPreApprovedVisitorRepository _visitorRepo;

    public MarkVisitorExitCommandHandler(
        IVisitorLogRepository logRepo,
        IPreApprovedVisitorRepository visitorRepo)
    {
        _logRepo = logRepo;
        _visitorRepo = visitorRepo;
    }

    public async Task<Unit> Handle(MarkVisitorExitCommand request, CancellationToken cancellationToken)
    {
        // 1. Find and update the PreApprovedVisitor status (PRIMARY — must succeed)
        var visitor = await _visitorRepo.GetByIdAsync(request.PreApprovalId)
            ?? throw new KeyNotFoundException("Visitor not found.");

        visitor.MarkAsExited();
        await _visitorRepo.UpdateAsync(visitor);

        Console.WriteLine($"🚪 VISITOR EXITED: {visitor.VisitorName} (ID: {visitor.Id})");

        // 2. Try to find an active VisitorLog (SECONDARY — best effort)
        var log = await _logRepo.GetActiveByPreApprovalIdAsync(request.PreApprovalId);

        if (log != null)
        {
            // Found the entry log — mark it as exited
            log.MarkExit();
            await _logRepo.UpdateAsync(log);
            Console.WriteLine($"   → Updated existing entry log. Exit time: {log.ExitTime}");
        }
        else
        {
            // No active log found — create one with exit already recorded
            Console.WriteLine($"   → No active entry log found. Creating exit log...");
            var exitLog = new VisitorLog(
                visitor.SocietyId,
                visitor.Id,
                visitor.VisitorName,
                visitor.VisitorMobile,
                visitor.FlatId,
                visitor.Purpose
            );
            exitLog.MarkExit();
            await _logRepo.AddAsync(exitLog);
            Console.WriteLine($"   → Exit log created. Log ID: {exitLog.Id}");
        }

        return Unit.Value;
    }
}