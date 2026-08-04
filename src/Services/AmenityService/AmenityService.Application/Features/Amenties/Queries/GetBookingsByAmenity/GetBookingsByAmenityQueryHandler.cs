using AmenityService.Application.DTOs;
using AmenityService.Domain.Interfaces;
using MediatR;

namespace AmenityService.Application.Features.Bookings.Queries.GetBookingsByAmenity;

public class GetBookingsByAmenityQueryHandler : IRequestHandler<GetBookingsByAmenityQuery, IReadOnlyList<AmenityBookingDto>>
{
    private readonly IUnitOfWork _unitOfWork;

    public GetBookingsByAmenityQueryHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<IReadOnlyList<AmenityBookingDto>> Handle(GetBookingsByAmenityQuery request, CancellationToken cancellationToken)
    {
        // Verify amenity belongs to society
        var belongsToSociety = await _unitOfWork.Amenities.IsOwnedBySocietyAsync(
            request.AmenityId, request.SocietyId, cancellationToken);

        if (!belongsToSociety)
            throw new UnauthorizedAccessException("Amenity does not belong to the specified society.");

        IReadOnlyList<Domain.Entities.AmenityBooking> bookings;

        if (!string.IsNullOrWhiteSpace(request.Date) && 
            DateOnly.TryParseExact(request.Date, "yyyy-MM-dd", out var date))
        {
            bookings = await _unitOfWork.AmenityBookings.GetByAmenityAndDateAsync(
                request.AmenityId, date, cancellationToken);
        }
        else
        {
            // Get bookings for next 7 days if no date specified
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var weekLater = today.AddDays(7);
            bookings = await _unitOfWork.AmenityBookings.GetByAmenityAndDateRangeAsync(
                request.AmenityId, today, weekLater, cancellationToken);
        }

        return bookings.Select(MapToDto).ToList();
    }

    private static AmenityBookingDto MapToDto(Domain.Entities.AmenityBooking b) => new(
        b.Id,
        b.AmenityId,
        b.Amenity?.Name ?? string.Empty,
        b.SocietyId,
        b.UserId,
        b.FlatNumber,
        b.BookingDate,
        b.StartTime.ToString("HH:mm"),
        b.EndTime.ToString("HH:mm"),
        b.Status,
        b.Notes,
        b.ApprovedBy,
        b.ApprovedAt,
        b.RejectionReason,
        b.CreatedAt);
}