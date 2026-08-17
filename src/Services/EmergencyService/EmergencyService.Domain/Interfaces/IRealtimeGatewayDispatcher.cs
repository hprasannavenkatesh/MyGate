namespace EmergencyService.Domain.Interfaces;

// Keeps the Application layer unaware of HTTP/SignalR specifics
public interface IRealtimeGatewayDispatcher
{
    Task BroadcastEmergencyAlertAsync(Guid societyId, object alertPayload, CancellationToken cancellationToken = default);
}