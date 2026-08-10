using VehicleService.Application.DTOs;
using VehicleService.Domain.Enums;
using MediatR;

namespace VehicleService.Application.Features.ParkingSlots.Queries.GetSlotsBySociety;

public record GetSlotsBySocietyQuery : IRequest<IReadOnlyList<ParkingSlotDto>>
{
    public Guid SocietyId { get; init; }
    public VehicleType? Type { get; init; }
    public bool? IsOccupied { get; init; }
}