using VehicleService.Domain.Enums;
using MediatR;

namespace VehicleService.Application.Features.ParkingSlots.Commands.CreateSlot;

public record CreateSlotCommand : IRequest<Guid>
{
    public Guid SocietyId { get; init; }
    public string SlotNumber { get; init; } = string.Empty;
    public VehicleType SlotType { get; init; }
    public string? BlockName { get; init; }

        public Guid? BlockId { get; init; }   // NEW
    public Guid? FlatId { get; init; }     // NEW
}