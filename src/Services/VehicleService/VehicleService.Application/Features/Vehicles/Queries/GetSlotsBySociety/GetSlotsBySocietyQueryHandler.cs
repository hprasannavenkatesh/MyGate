using VehicleService.Application.DTOs;
using VehicleService.Domain.Interfaces;
using MediatR;

namespace VehicleService.Application.Features.ParkingSlots.Queries.GetSlotsBySociety;

public class GetSlotsBySocietyQueryHandler : IRequestHandler<GetSlotsBySocietyQuery, IReadOnlyList<ParkingSlotDto>>
{
    private readonly IUnitOfWork _unitOfWork;

    public GetSlotsBySocietyQueryHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<IReadOnlyList<ParkingSlotDto>> Handle(GetSlotsBySocietyQuery request, CancellationToken cancellationToken)
    {
        var slots = await _unitOfWork.ParkingSlots.GetBySocietyAsync(
            request.SocietyId, request.Type, request.IsOccupied, cancellationToken);

        return slots.Select(s => new ParkingSlotDto(
            s.Id,
    s.SlotNumber,
    s.SlotType,
    s.BlockId,
    s.FlatId,
    s.FlatId.HasValue, // IsAllotted
    s.IsOccupied
        )).ToList();
    }
}