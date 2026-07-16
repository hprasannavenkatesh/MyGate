using MediatR;
using VisitorService.Domain.Interfaces;

namespace VisitorService.Application.Features.Visitors.Commands;

public class MarkVisitorExitCommandHandler : IRequestHandler<MarkVisitorExitCommand, Unit>
{
    private readonly IVisitorLogRepository _logRepo;

    public MarkVisitorExitCommandHandler(IVisitorLogRepository logRepo)
    {
        _logRepo = logRepo;
    }

    public async Task<Unit> Handle(MarkVisitorExitCommand request, CancellationToken cancellationToken)
    {
        // 1. Find the log
        var log = await _logRepo.GetByIdAsync(request.LogId)
            ?? throw new KeyNotFoundException("Visitor log not found.");

        // 2. Use our Domain method to mark exit and set the time
        log.MarkExit();

        // Note: In a real app, we'd call `_logRepo.UpdateAsync(log)` here. 
        // For this speed run, we'll just let it complete successfully.
           // 2. Use our Domain method to mark exit and set the time
        log.MarkExit();

        // 3. ACTUALLY SAVE IT TO THE DATABASE THIS TIME!
        await _logRepo.UpdateAsync(log);
        
        Console.WriteLine($"🚪 GATE LOG SAVED: Visitor {log.VisitorName} exited at {log.ExitTime}");

        return Unit.Value;
    }
}