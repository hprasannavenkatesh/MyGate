using MediatR;

namespace AmenityService.Application.Features.Bookings.Commands.CancelBooking;

public record CancelBookingCommand : IRequest<Unit>
{
    public Guid Id { get; init; }
    public Guid SocietyId { get; init; }
    public Guid UserId { get; init; }
}