using EmergencyService.Domain.Enums;
using MediatR;

namespace EmergencyService.Application.Features.Alerts.Commands.TriggerPanic;

public record TriggerPanicCommand : IRequest<Guid>
{
    public Guid SocietyId { get; init; }
    public Guid FlatId { get; init; }
    public EmergencyType Type { get; init; }
    public string? Description { get; init; }
}