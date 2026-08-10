using VehicleService.Application.DTOs;
using VehicleService.Domain.Interfaces;
using MediatR;

namespace VehicleService.Application.Features.Vehicles.Queries.GetMyVehicles;

public class GetMyVehiclesQueryHandler : IRequestHandler<GetMyVehiclesQuery, IReadOnlyList<VehicleDto>>
{
    private readonly IUnitOfWork _unitOfWork;

    public GetMyVehiclesQueryHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<IReadOnlyList<VehicleDto>> Handle(GetMyVehiclesQuery request, CancellationToken cancellationToken)
    {
        var vehicles = await _unitOfWork.Vehicles.GetByOwnerAsync(request.SocietyId, request.UserId, cancellationToken);
        return vehicles.Select(v => new VehicleDto(
            v.Id,
            v.VehicleNumber,
            v.VehicleType,
            v.MakeModel,
            v.ParkingSlot?.SlotNumber,
            v.ParkingSlotId.HasValue
        )).ToList();
    }
}