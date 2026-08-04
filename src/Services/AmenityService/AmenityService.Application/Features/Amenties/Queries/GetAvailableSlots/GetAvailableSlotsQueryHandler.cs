using AmenityService.Application.DTOs;
using AmenityService.Domain.Interfaces;
using MediatR;

namespace AmenityService.Application.Features.Bookings.Queries.GetAvailableSlots;

public class GetAvailableSlotsQueryHandler : IRequestHandler<GetAvailableSlotsQuery, IReadOnlyList<AvailableSlotDto>>
{
    private readonly IUnitOfWork _unitOfWork;

    public GetAvailableSlotsQueryHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<IReadOnlyList<AvailableSlotDto>> Handle(GetAvailableSlotsQuery request, CancellationToken cancellationToken)
    {
        // 1. Get amenity with slot configuration
        var amenity = await _unitOfWork.Amenities.GetByIdAsync(request.AmenityId, cancellationToken)
            ?? throw new KeyNotFoundException($"Amenity with ID {request.AmenityId} not found.");

        if (amenity.SocietyId != request.SocietyId)
            throw new UnauthorizedAccessException("Amenity does not belong to the specified society.");

        if (!amenity.IsActive || !amenity.IsBookable)
            return Array.Empty<AvailableSlotDto>();

        // 2. Parse date and validate
        var bookingDate = DateOnly.ParseExact(request.Date, "yyyy-MM-dd");
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var maxDate = today.AddDays(amenity.AdvanceBookingDaysAllowed);

        if (bookingDate < today || bookingDate > maxDate)
            throw new InvalidOperationException("Selected date is outside the allowed booking range.");

        // 3. Get existing bookings for that date
        var existingBookings = await _unitOfWork.AmenityBookings.GetByAmenityAndDateAsync(
            request.AmenityId, bookingDate, cancellationToken);

        var activeBookings = existingBookings
            .Where(b => b.Status is Domain.Enums.BookingStatus.Pending or Domain.Enums.BookingStatus.Approved)
            .ToList();

        // 4. Generate all possible slots
        var slots = new List<AvailableSlotDto>();
        var currentTime = amenity.OperatingHoursStart;
        var slotDuration = TimeSpan.FromMinutes(amenity.SlotDurationMinutes);

        while (currentTime.Add(slotDuration) <= amenity.OperatingHoursEnd)
        {
            var slotEnd = currentTime.Add(slotDuration);
            var isAvailable = !activeBookings.Any(b => b.IsTimeOverlapping(currentTime, slotEnd));

            // Additional check: if date is today, past slots are not available
            if (bookingDate == today)
            {
                var nowTime = TimeOnly.FromDateTime(DateTime.UtcNow);
                if (currentTime <= nowTime)
                    isAvailable = false;
            }

            slots.Add(new AvailableSlotDto(
                StartTime: currentTime.ToString("HH:mm"),
                EndTime: slotEnd.ToString("HH:mm"),
                IsAvailable: isAvailable));

            currentTime = slotEnd;
        }

        return slots;
    }
}