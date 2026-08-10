using MediatR;

namespace VehicleService.Application.Features.ParkingSlots.Commands.AssignSlot;

public record AssignSlotCommand : IRequest<Unit>
{
    public Guid VehicleId { get; init; }
    public Guid SlotId { get; init; }
    public Guid SocietyId { get; init; }
}