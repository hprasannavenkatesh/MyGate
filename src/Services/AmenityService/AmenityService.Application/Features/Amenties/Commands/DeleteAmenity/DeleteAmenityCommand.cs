using MediatR;

namespace AmenityService.Application.Features.Amenities.Commands.DeleteAmenity;

public record DeleteAmenityCommand : IRequest<Unit>
{
    public Guid Id { get; init; }
    public Guid SocietyId { get; init; }
}