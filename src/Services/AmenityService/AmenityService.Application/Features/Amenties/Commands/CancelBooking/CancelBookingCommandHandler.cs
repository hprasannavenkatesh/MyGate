using AmenityService.Domain.Interfaces;
using MediatR;

namespace AmenityService.Application.Features.Bookings.Commands.CancelBooking;

public class CancelBookingCommandHandler : IRequestHandler<CancelBookingCommand, Unit>
{
    private readonly IUnitOfWork _unitOfWork;

    public CancelBookingCommandHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<Unit> Handle(CancelBookingCommand request, CancellationToken cancellationToken)
    {
        var booking = await _unitOfWork.AmenityBookings.GetByIdAsync(request.Id, cancellationToken)
            ?? throw new KeyNotFoundException($"Booking with ID {request.Id} not found.");

        if (booking.SocietyId != request.SocietyId)
            throw new UnauthorizedAccessException("You do not have access to this booking.");

        if (booking.UserId != request.UserId)
            throw new UnauthorizedAccessException("You can only cancel your own bookings.");

        // Check if booking is in the past
        var bookingDateTime = booking.BookingDate.ToDateTime(booking.StartTime);
        if (bookingDateTime < DateTime.UtcNow)
            throw new InvalidOperationException("Cannot cancel a booking that has already passed.");

        booking.Cancel();
        _unitOfWork.AmenityBookings.Update(booking);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Unit.Value;
    }
}