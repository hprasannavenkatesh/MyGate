using AmenityService.Application.DTOs;
using MediatR;

namespace AmenityService.Application.Features.Amenities.Queries.GetAmenitiesBySociety;

public record GetAmenitiesBySocietyQuery : IRequest<IReadOnlyList<AmenityDto>>
{
    public Guid SocietyId { get; init; }
    public bool ActiveOnly { get; init; } = true;
}