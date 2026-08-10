using VehicleService.Application.DTOs;
using MediatR;

namespace VehicleService.Application.Features.Vehicles.Queries.GetMyVehicles;

public record GetMyVehiclesQuery : IRequest<IReadOnlyList<VehicleDto>>
{
    public Guid SocietyId { get; init; }
    public Guid UserId { get; init; }
}