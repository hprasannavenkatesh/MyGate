using MediatR;

namespace TenantService.Application.Features.Societies.Commands;

public record DeleteSocietyCommand : IRequest<Unit>
{
    public Guid SocietyId { get; init; }
}