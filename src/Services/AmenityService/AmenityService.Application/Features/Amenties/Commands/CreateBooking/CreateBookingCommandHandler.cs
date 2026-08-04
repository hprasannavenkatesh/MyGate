using AmenityService.Domain.Interfaces;
using MediatR;

namespace AmenityService.Application.Features.Bookings.Commands.CreateBooking;

public class CreateBookingCommandHandler : IRequestHandler<CreateBookingCommand, Guid>
{
    private readonly IUnitOfWork _unitOfWork;

    public CreateBookingCommandHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<Guid> Handle(CreateBookingCommand request, CancellationToken cancellationToken)
    {
        // 1. Validate amenity exists, is active, is bookable, and belongs to society
        var amenity = await _unitOfWork.Amenities.GetByIdAsync(request.AmenityId, cancellationToken)
            ?? throw new KeyNotFoundException($"Amenity with ID {request.AmenityId} not found.");

        if (amenity.SocietyId != request.SocietyId)
            throw new UnauthorizedAccessException("Amenity does not belong to the specified society.");

        if (!amenity.IsActive)
            throw new InvalidOperationException("This amenity is currently inactive.");

        if (!amenity.IsBookable)
            throw new InvalidOperationException("This amenity does not support bookings.");

        // 2. Parse and validate date/time
        var bookingDate = DateOnly.ParseExact(request.BookingDate, "yyyy-MM-dd");
        var startTime = TimeOnly.Parse(request.StartTime);
        var endTime = TimeOnly.Parse(request.EndTime);

        // 3. Check booking date is within allowed range
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var maxDate = today.AddDays(amenity.AdvanceBookingDaysAllowed);

        if (bookingDate < today)
            throw new InvalidOperationException("Cannot book a slot in the past.");

        if (bookingDate > maxDate)
            throw new InvalidOperationException($"Bookings can only be made up to {amenity.AdvanceBookingDaysAllowed} days in advance.");

        // 4. Check time is within operating hours
        if (startTime < amenity.OperatingHoursStart || endTime > amenity.OperatingHoursEnd)
            throw new InvalidOperationException($"Booking must be within operating hours: {amenity.OperatingHoursStart:HH:mm} - {amenity.OperatingHoursEnd:HH:mm}.");

        // 5. Check slot duration matches amenity config
        var requestedDuration = endTime - startTime;
        if (requestedDuration.TotalMinutes != amenity.SlotDurationMinutes)
            throw new InvalidOperationException($"Slot duration must be exactly {amenity.SlotDurationMinutes} minutes.");

        // 6. Check for overlapping bookings
        var hasOverlap = await _unitOfWork.AmenityBookings.HasOverlappingBookingAsync(
            request.AmenityId, bookingDate, startTime, endTime, cancellationToken);

        if (hasOverlap)
            throw new InvalidOperationException("This time slot is already booked.");

        // 7. Check user's daily booking limit
        var userBookingsCount = await _unitOfWork.AmenityBookings.CountUserBookingsForDateAsync(
            request.UserId, request.AmenityId, bookingDate, cancellationToken);

        if (userBookingsCount >= amenity.MaxBookingsPerDayPerUser)
            throw new InvalidOperationException($"You can only book this amenity {amenity.MaxBookingsPerDayPerUser} time(s) per day.");

        // 8. Create booking
        var booking = Domain.Entities.AmenityBooking.Create(
            amenityId: request.AmenityId,
            societyId: request.SocietyId,
            userId: request.UserId,
            flatNumber: request.FlatNumber,
            bookingDate: bookingDate,
            startTime: startTime,
            endTime: endTime,
            notes: request.Notes);

        _unitOfWork.AmenityBookings.Add(booking);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return booking.Id;
    }
}