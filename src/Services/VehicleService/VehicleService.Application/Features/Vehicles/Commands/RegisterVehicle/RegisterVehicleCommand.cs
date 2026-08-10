using VehicleService.Domain.Enums;
using MediatR;

namespace VehicleService.Application.Features.Vehicles.Commands.RegisterVehicle;

public record RegisterVehicleCommand : IRequest<Guid>
{
    public Guid SocietyId { get; init; }
    public Guid FlatId { get; init; }
    public Guid OwnerId { get; init; } // <-- ADD THIS LINE
    public string VehicleNumber { get; init; } = string.Empty;
    public VehicleType VehicleType { get; init; }
    public string? MakeModel { get; init; }
}