using AmenityService.Domain.Interfaces;
using MediatR;

namespace AmenityService.Application.Features.Bookings.Commands.RejectBooking;

public class RejectBookingCommandHandler : IRequestHandler<RejectBookingCommand, Unit>
{
    private readonly IUnitOfWork _unitOfWork;

    public RejectBookingCommandHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<Unit> Handle(RejectBookingCommand request, CancellationToken cancellationToken)
    {
        var booking = await _unitOfWork.AmenityBookings.GetByIdAsync(request.Id, cancellationToken)
            ?? throw new KeyNotFoundException($"Booking with ID {request.Id} not found.");

        if (booking.SocietyId != request.SocietyId)
            throw new UnauthorizedAccessException("You do not have access to this booking.");

        booking.Reject(request.AdminUserId, request.Reason);
        _unitOfWork.AmenityBookings.Update(booking);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Unit.Value;
    }
}