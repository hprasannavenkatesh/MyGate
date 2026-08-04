using AmenityService.Application.DTOs;
using AmenityService.Domain.Interfaces;
using MediatR;

namespace AmenityService.Application.Features.Amenities.Queries.GetAmenitiesBySociety;

public class GetAmenitiesBySocietyQueryHandler : IRequestHandler<GetAmenitiesBySocietyQuery, IReadOnlyList<AmenityDto>>
{
    private readonly IUnitOfWork _unitOfWork;

    public GetAmenitiesBySocietyQueryHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<IReadOnlyList<AmenityDto>> Handle(GetAmenitiesBySocietyQuery request, CancellationToken cancellationToken)
    {
        var amenities = request.ActiveOnly
            ? await _unitOfWork.Amenities.GetActiveBySocietyIdAsync(request.SocietyId, cancellationToken)
            : await _unitOfWork.Amenities.GetBySocietyIdAsync(request.SocietyId, cancellationToken);

        return amenities.Select(MapToDto).ToList();
    }

    private static AmenityDto MapToDto(Domain.Entities.Amenity a) => new(
        a.Id,
        a.SocietyId,
        a.Name,
        a.Description,
        a.Location,
        a.IsActive,
        a.IsBookable,
        a.SlotDurationMinutes,
        a.MaxBookingsPerDayPerUser,
        a.AdvanceBookingDaysAllowed,
        a.OperatingHoursStart.ToString("HH:mm"),
        a.OperatingHoursEnd.ToString("HH:mm"),
        a.CreatedAt);
}