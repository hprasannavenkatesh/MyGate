using AmenityService.Domain.Entities;
using AmenityService.Domain.Interfaces;
using MediatR;

namespace AmenityService.Application.Features.Amenities.Commands.CreateAmenity;

public class CreateAmenityCommandHandler : IRequestHandler<CreateAmenityCommand, Guid>
{
    private readonly IUnitOfWork _unitOfWork;

    public CreateAmenityCommandHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<Guid> Handle(CreateAmenityCommand request, CancellationToken cancellationToken)
    {
        var operatingStart = TimeOnly.Parse(request.OperatingHoursStart);
        var operatingEnd = TimeOnly.Parse(request.OperatingHoursEnd);

        var amenity = Amenity.Create(
            societyId: request.SocietyId,
            name: request.Name,
            description: request.Description,
            location: request.Location,
            isBookable: request.IsBookable,
            slotDurationMinutes: request.SlotDurationMinutes,
            maxBookingsPerDayPerUser: request.MaxBookingsPerDayPerUser,
            advanceBookingDaysAllowed: request.AdvanceBookingDaysAllowed,
            operatingHoursStart: operatingStart,
            operatingHoursEnd: operatingEnd);

        _unitOfWork.Amenities.Add(amenity);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return amenity.Id;
    }
}