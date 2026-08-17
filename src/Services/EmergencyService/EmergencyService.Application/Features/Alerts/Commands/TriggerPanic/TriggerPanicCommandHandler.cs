using EmergencyService.Domain.Interfaces;
using MediatR;

namespace EmergencyService.Application.Features.Alerts.Commands.TriggerPanic;

public class TriggerPanicCommandHandler : IRequestHandler<TriggerPanicCommand, Guid>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IRealtimeGatewayDispatcher _gateway;

    public TriggerPanicCommandHandler(IUnitOfWork unitOfWork, IRealtimeGatewayDispatcher gateway)
    {
        _unitOfWork = unitOfWork;
        _gateway = gateway;
    }

    public async Task<Guid> Handle(TriggerPanicCommand request, CancellationToken cancellationToken)
    {
        var alert = Domain.Entities.EmergencyAlert.Create(
            request.SocietyId, Guid.Empty, request.FlatId, request.Type, request.Description);
        // Guid.Empty will be overwritten by Controller with real UserId

        _unitOfWork.Alerts.Add(alert);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // 1. Broadcast to SignalR Gateway
        var payload = new { alert.Id, alert.Type, alert.Description, TriggeredAt = alert.CreatedAt };
        await _gateway.BroadcastEmergencyAlertAsync(alert.SocietyId, payload, cancellationToken);

        return alert.Id;
    }
}                                                                                                                               