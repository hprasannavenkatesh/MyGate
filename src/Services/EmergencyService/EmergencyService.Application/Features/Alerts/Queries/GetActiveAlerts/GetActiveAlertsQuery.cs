using EmergencyService.Application.DTOs;
using MediatR;

namespace EmergencyService.Application.Features.Alerts.Queries.GetActiveAlerts;

public record GetActiveAlertsQuery : IRequest<IReadOnlyList<EmergencyAlertDto>>
{
    public Guid SocietyId { get; init; }
}