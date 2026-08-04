using AmenityService.Application.DTOs;
using MediatR;

namespace AmenityService.Application.Features.Bookings.Queries.GetPendingBookings;

public record GetPendingBookingsQuery : IRequest<IReadOnlyList<AmenityBookingDto>>
{
    public Guid SocietyId { get; init; }
}