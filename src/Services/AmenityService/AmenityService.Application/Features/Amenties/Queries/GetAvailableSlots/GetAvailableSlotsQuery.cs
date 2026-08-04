using AmenityService.Application.DTOs;
using MediatR;

namespace AmenityService.Application.Features.Bookings.Queries.GetAvailableSlots;

public record GetAvailableSlotsQuery : IRequest<IReadOnlyList<AvailableSlotDto>>
{
    public Guid AmenityId { get; init; }
    public Guid SocietyId { get; init; }
    public string Date { get; init; } = string.Empty; // YYYY-MM-DD
}