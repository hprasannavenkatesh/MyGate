using VehicleService.Domain.Interfaces;
using MediatR;

namespace VehicleService.Application.Features.ParkingSlots.Commands.CreateSlot;

public class CreateSlotCommandHandler : IRequestHandler<CreateSlotCommand, Guid>
{
    private readonly IUnitOfWork _unitOfWork;

    public CreateSlotCommandHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Guid> Handle(CreateSlotCommand request, CancellationToken cancellationToken)
    {
        var isTaken = await _unitOfWork.ParkingSlots.IsSlotNumberTakenAsync(request.SocietyId, request.SlotNumber, cancellationToken);
        if (isTaken) throw new InvalidOperationException($"Slot number '{request.SlotNumber}' already exists in this society.");

        var slot = Domain.Entities.ParkingSlot.Create(
            request.SocietyId, request.SlotNumber, request.SlotType, request.BlockId, request.FlatId);

        _unitOfWork.ParkingSlots.Add(slot);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return slot.Id;
    }
}