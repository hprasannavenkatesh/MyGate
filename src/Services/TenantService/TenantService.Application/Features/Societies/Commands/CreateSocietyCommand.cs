using MediatR;

namespace TenantService.Application.Features.Societies.Commands;

public class CreateSocietyCommand : IRequest<Guid>
{
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
}