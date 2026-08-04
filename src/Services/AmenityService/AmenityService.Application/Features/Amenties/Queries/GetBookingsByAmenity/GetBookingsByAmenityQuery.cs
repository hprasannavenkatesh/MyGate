using AmenityService.Application.DTOs;
using MediatR;

namespace AmenityService.Application.Features.Bookings.Queries.GetBookingsByAmenity;

public record GetBookingsByAmenityQuery : IRequest<IReadOnlyList<AmenityBookingDto>>
{
    public Guid AmenityId { get; init; }
    public Guid SocietyId { get; init; }
    public string? Date { get; init; } // Optional: YYYY-MM-DD filter
}