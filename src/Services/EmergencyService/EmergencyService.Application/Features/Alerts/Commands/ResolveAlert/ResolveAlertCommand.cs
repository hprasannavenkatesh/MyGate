using MediatR;

namespace EmergencyService.Application.Features.Alerts.Commands.ResolveAlert;

public record ResolveAlertCommand : IRequest<Unit>
{
    public Guid AlertId { get; init; }
    public Guid SocietyId { get; init; }
}