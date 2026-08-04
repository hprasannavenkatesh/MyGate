using MediatR;

namespace AmenityService.Application.Features.Bookings.Commands.CreateBooking;

public record CreateBookingCommand : IRequest<Guid>
{
    public Guid AmenityId { get; init; }
    public Guid SocietyId { get; init; }
    public Guid UserId { get; init; }
    public string FlatNumber { get; init; } = string.Empty;
    public string BookingDate { get; init; } = string.Empty; // YYYY-MM-DD
    public string StartTime { get; init; } = string.Empty;   // HH:mm
    public string EndTime { get; init; } = string.Empty;     // HH:mm
    public string? Notes { get; init; }
}