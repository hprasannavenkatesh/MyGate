using AmenityService.Application.DTOs;
using MediatR;

namespace AmenityService.Application.Features.Amenities.Queries.GetAmenityById;

public record GetAmenityByIdQuery : IRequest<AmenityDto>
{
    public Guid Id { get; init; }
    public Guid SocietyId { get; init; }
}