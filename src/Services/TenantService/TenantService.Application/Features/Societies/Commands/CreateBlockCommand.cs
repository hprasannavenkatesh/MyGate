using MediatR;

namespace TenantService.Application.Features.Societies.Commands;

public class CreateBlockCommand : IRequest<Guid>
{
    public Guid SocietyId { get; set; }
    public string Name { get; set; } = string.Empty;
}