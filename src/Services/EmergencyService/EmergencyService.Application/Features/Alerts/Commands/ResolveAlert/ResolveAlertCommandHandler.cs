using EmergencyService.Domain.Interfaces;
using MediatR;

namespace EmergencyService.Application.Features.Alerts.Commands.ResolveAlert;

public class ResolveAlertCommandHandler : IRequestHandler<ResolveAlertCommand, Unit>
{
    private readonly IUnitOfWork _unitOfWork;

    public ResolveAlertCommandHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Unit> Handle(ResolveAlertCommand request, CancellationToken cancellationToken)
    {
        var alert = await _unitOfWork.Alerts.GetByIdAsync(request.AlertId, cancellationToken)
            ?? throw new KeyNotFoundException("Alert not found.");

        if (alert.SocietyId != request.SocietyId) throw new UnauthorizedAccessException();

        // We pass Guid.Empty here, Controller will override with real Admin/Guard ID
        alert.Resolve(Guid.Empty); 
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return Unit.Value;
    }
}