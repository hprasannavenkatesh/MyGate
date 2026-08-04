using AmenityService.Domain.Interfaces;
using MediatR;

namespace AmenityService.Application.Features.Bookings.Commands.ApproveBooking;

public class ApproveBookingCommandHandler : IRequestHandler<ApproveBookingCommand, Unit>
{
    private readonly IUnitOfWork _unitOfWork;

    public ApproveBookingCommandHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<Unit> Handle(ApproveBookingCommand request, CancellationToken cancellationToken)
    {
        var booking = await _unitOfWork.AmenityBookings.GetByIdAsync(request.Id, cancellationToken)
            ?? throw new KeyNotFoundException($"Booking with ID {request.Id} not found.");

        if (booking.SocietyId != request.SocietyId)
            throw new UnauthorizedAccessException("You do not have access to this booking.");

        booking.Approve(request.AdminUserId);
        _unitOfWork.AmenityBookings.Update(booking);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Unit.Value;
    }
}