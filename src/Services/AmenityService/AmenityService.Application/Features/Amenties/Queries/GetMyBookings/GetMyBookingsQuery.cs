using AmenityService.Application.DTOs;
using MediatR;

namespace AmenityService.Application.Features.Bookings.Queries.GetMyBookings;

public record GetMyBookingsQuery : IRequest<IReadOnlyList<AmenityBookingDto>>
{
    public Guid UserId { get; init; }
    public Guid SocietyId { get; init; }
}