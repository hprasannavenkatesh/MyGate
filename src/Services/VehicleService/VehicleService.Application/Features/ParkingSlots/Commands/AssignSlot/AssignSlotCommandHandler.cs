using VehicleService.Domain.Interfaces;
using MediatR;

namespace VehicleService.Application.Features.ParkingSlots.Commands.AssignSlot;

public class AssignSlotCommandHandler : IRequestHandler<AssignSlotCommand, Unit>
{
    private readonly IUnitOfWork _unitOfWork;

    public AssignSlotCommandHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Unit> Handle(AssignSlotCommand request, CancellationToken cancellationToken)
    {
        var vehicle = await _unitOfWork.Vehicles.GetByIdAsync(request.VehicleId, cancellationToken)
            ?? throw new KeyNotFoundException("Vehicle not found.");
        
        if (vehicle.SocietyId != request.SocietyId) throw new UnauthorizedAccessException();

        var slot = await _unitOfWork.ParkingSlots.GetByIdAsync(request.SlotId, cancellationToken)
            ?? throw new KeyNotFoundException("Parking slot not found.");

        if (slot.SocietyId != request.SocietyId) throw new UnauthorizedAccessException();

        // THE CORE BUSINESS RULE: Type mismatch check!
        // Residents (2W/4W) must match slots (2W/4W). 
        // Visitors must go to Visitor slots.
        if (vehicle.VehicleType != slot.SlotType)
            throw new InvalidOperationException($"Cannot park a {vehicle.VehicleType} in a {slot.SlotType} slot.");

        if (slot.IsOccupied)
            throw new InvalidOperationException("This parking slot is already occupied.");

        // If vehicle was in another slot, free up the old slot
        if (vehicle.ParkingSlotId.HasValue && vehicle.ParkingSlotId != request.SlotId)
        {
            var oldSlot = await _unitOfWork.ParkingSlots.GetByIdAsync(vehicle.ParkingSlotId.Value, cancellationToken);
            if (oldSlot != null) oldSlot.MarkVacant();
        }

        // Assign new slot
        vehicle.AssignSlot(request.SlotId);
        slot.MarkOccupied();

        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return Unit.Value;
    }
}