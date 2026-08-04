using AmenityService.Application.DTOs;
using AmenityService.Domain.Interfaces;
using MediatR;

namespace AmenityService.Application.Features.Amenities.Queries.GetAmenityById;

public class GetAmenityByIdQueryHandler : IRequestHandler<GetAmenityByIdQuery, AmenityDto>
{
    private readonly IUnitOfWork _unitOfWork;

    public GetAmenityByIdQueryHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<AmenityDto> Handle(GetAmenityByIdQuery request, CancellationToken cancellationToken)
    {
        var amenity = await _unitOfWork.Amenities.GetByIdAsync(request.Id, cancellationToken)
            ?? throw new KeyNotFoundException($"Amenity with ID {request.Id} not found.");

        if (amenity.SocietyId != request.SocietyId)
            throw new UnauthorizedAccessException("You do not have access to this amenity.");

        return new AmenityDto(
            amenity.Id,
            amenity.SocietyId,
            amenity.Name,
            amenity.Description,
            amenity.Location,
            amenity.IsActive,
            amenity.IsBookable,
            amenity.SlotDurationMinutes,
            amenity.MaxBookingsPerDayPerUser,
            amenity.AdvanceBookingDaysAllowed,
            amenity.OperatingHoursStart.ToString("HH:mm"),
            amenity.OperatingHoursEnd.ToString("HH:mm"),
            amenity.CreatedAt);
    }
}