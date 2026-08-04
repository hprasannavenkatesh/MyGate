using MediatR;

namespace AmenityService.Application.Features.Bookings.Commands.ApproveBooking;

public record ApproveBookingCommand : IRequest<Unit>
{
    public Guid Id { get; init; }
    public Guid SocietyId { get; init; }
    public Guid AdminUserId { get; init; }
}