// AmenityService/AmenityService.Application/Features/Amenities/Commands/UpdateAmenity/UpdateAmenityCommandHandler.cs

using AmenityService.Domain.Entities;
using AmenityService.Domain.Interfaces;
using MediatR;

namespace AmenityService.Application.Features.Amenities.Commands.UpdateAmenity;

public class UpdateAmenityCommandHandler : IRequestHandler<UpdateAmenityCommand, Unit>
{
    private readonly IUnitOfWork _unitOfWork;

    public UpdateAmenityCommandHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<Unit> Handle(UpdateAmenityCommand request, CancellationToken cancellationToken)
    {
        // 1. Get the amenity
        var amenity = await _unitOfWork.Amenities.GetByIdAsync(request.Id, cancellationToken)
            ?? throw new KeyNotFoundException($"Amenity with ID {request.Id} not found.");

        // 2. Security: Ensure amenity belongs to the specified society
        if (amenity.SocietyId != request.SocietyId)
            throw new UnauthorizedAccessException("You do not have access to this amenity.");

        // 3. Update fields using domain method
        var operatingStart = TimeOnly.Parse(request.OperatingHoursStart);
        var operatingEnd = TimeOnly.Parse(request.OperatingHoursEnd);

        amenity.Update(
            name: request.Name,
            description: request.Description,
            location: request.Location,
            isBookable: request.IsBookable,
            slotDurationMinutes: request.SlotDurationMinutes,
            maxBookingsPerDayPerUser: request.MaxBookingsPerDayPerUser,
            advanceBookingDaysAllowed: request.AdvanceBookingDaysAllowed,
            operatingHoursStart: operatingStart,
            operatingHoursEnd: operatingEnd);

        // 4. Persist
        _unitOfWork.Amenities.Update(amenity);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Unit.Value;
    }
}