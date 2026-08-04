using MediatR;

namespace AmenityService.Application.Features.Bookings.Commands.RejectBooking;

public record RejectBookingCommand : IRequest<Unit>
{
    public Guid Id { get; init; }
    public Guid SocietyId { get; init; }
    public Guid AdminUserId { get; init; }
    public string Reason { get; init; } = string.Empty;
}